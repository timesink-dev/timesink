defmodule Timesink.Locations do
  @moduledoc """
  The `Timesink.Locations` module provides a unified and cache-optimized interface for
  performing location-based lookups using configurable data providers.

  It supports both:

  * **Autocomplete queries** for cities (via `get_locations/2`)
  * **Detailed geolocation lookups** (lat/lng) by `place_id` (via `lookup_place/1`)

  ## Features

  - Plug-and-play backend system using the `Timesink.Locations.Provider` behaviour.
  - Concurrent query execution across providers using `Task.Supervisor`.
  - In-memory ETS caching for performance and reduced API calls (via `Timesink.Locations.Cache`).

  ## Examples

  Autocomplete cities:

    iex> Timesink.Locations.get_locations("New Yo")
    {:ok, [%{label: "New York, NY, United States", city: "New York", ...}]}

  Get precise latitude and longitude:

    iex> Timesink.Locations.lookup_place("here:cm:namedplace:123456")
    {:ok, %{lat: 40.7128, lng: -74.006}}

  Cached results are returned instantly if available.

  ## Default Provider

  By default, the module uses:

  * `Timesink.Locations.HereMaps` — a HERE Maps-based autocomplete and lookup provider.

   You can configure different providers (like HERE, Mapbox, etc.) by implementing the `Timesink.Locations.Provider` behaviour.and adding them to the `@provider` list.

  """
  alias Timesink.Locations.{Cache, Result, HereMaps}
  @provider [HereMaps]

  def get_locations(query, opts \\ []) do
    if String.length(query) < 2 do
      {:ok, []}
    else
      {:ok, do_lookup(query, opts)}
    end
  end

  def lookup_place(place_id) do
    with {:ok, result} <- Cache.fetch({:lookup, place_id}) do
      {:ok, result}
    else
      :miss ->
        with {:ok, coords} <- HereMaps.lookup(place_id) do
          :ok = Cache.put({:lookup, place_id}, coords)
          {:ok, coords}
        end
    end
  end

  defp do_lookup(query, opts) do
    limit = Keyword.get(opts, :limit, 5)
    timeout = Keyword.get(opts, :timeout, 5_000)

    {uncached, cached} = fetch_cached(@provider, query, limit)

    uncached
    |> Enum.map(&async_query(&1, query, opts))
    |> Task.yield_many(timeout)
    |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
    |> Enum.flat_map(fn
      {:ok, results} -> results
      _ -> []
    end)
    |> write_to_cache(query, limit)
    |> Kernel.++(cached)
    |> Enum.take(limit)
    |> Enum.flat_map(& &1.locations)
  end

  defp fetch_cached(provider, query, limit) do
    Enum.reduce(provider, {[], []}, fn provider, {uncached, acc} ->
      key = {provider.name(), query, limit}

      case Cache.fetch(key) do
        {:ok, result} -> {uncached, [result | acc]}
        :miss -> {[provider | uncached], acc}
      end
    end)
  end

  defp async_query(provider, query, opts) do
    Task.Supervisor.async_nolink(
      Timesink.TaskSupervisor,
      provider,
      :compute,
      [query, opts]
    )
  end

  defp write_to_cache(results, query, limit) do
    Enum.map(results, fn %Result{provider: provider} = result ->
      Cache.put({provider.name(), query, limit}, result)
      result
    end)
  end
end
