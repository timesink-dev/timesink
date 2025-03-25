defmodule Timesink.Locations do
  @moduledoc """
  Provides a unified interface for performing location autocomplete lookups using pluggable data providers.

  This module handles:
  - Querying one or more `LocationProvider` modules (e.g. `HereMaps`)
  - Concurrently executing provider requests using `Task.Supervisor`
  - Caching results for performance via ETS (`Timesink.Locations.Cache`)

  ## Example:

      iex> Timesink.Locations.get_locations("Los An")
      {:ok, [%{city: "Los Angeles", country_code: "USA", ...}, ...]}

  You can configure different backends/providers (like HERE, Mapbox, etc.) by implementing the `Timesink.Locations.Provider` behaviour.
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
        :error -> {[provider | uncached], acc}
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
