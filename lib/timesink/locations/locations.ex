defmodule Timesink.Locations do
  alias Timesink.Locations.{Cache, Result, HereMaps}
  @backends [HereMaps]

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

    {uncached, cached} = fetch_cached(@backends, query, limit)

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

  defp fetch_cached(backends, query, limit) do
    Enum.reduce(backends, {[], []}, fn backend, {uncached, acc} ->
      key = {backend.name(), query, limit}

      case Cache.fetch(key) do
        {:ok, result} -> {uncached, [result | acc]}
        :error -> {[backend | uncached], acc}
      end
    end)
  end

  defp async_query(backend, query, opts) do
    Task.Supervisor.async_nolink(
      Timesink.TaskSupervisor,
      backend,
      :compute,
      [query, opts]
    )
  end

  defp write_to_cache(results, query, limit) do
    Enum.map(results, fn %Result{backend: backend} = result ->
      Cache.put({backend.name(), query, limit}, result)
      result
    end)
  end
end
