defmodule Timesink.Locations.Cache do
  @moduledoc """
  A simple in-memory caching layer for storing geolocation search results.

  Backed by ETS (`:ets`), this cache:
  - Supports named tables for safe concurrent access.
  - Periodically clears itself every 10 minutes to avoid stale data.
  - Is used by `Timesink.Locations` to reduce unnecessary API calls.

  ## Example

      # Store a result
      Cache.put({MyProvider.name(), "Los Angeles", 5}, result)

      # Fetch a result
      Cache.fetch({MyProvider.name(), "Los Angeles", 5})

  This GenServer runs as part of Timesink's application supervision tree.
  """
  use GenServer

  @clear_interval :timer.minutes(10)

  def put(name \\ __MODULE__, key, value) do
    true = :ets.insert(tab_name(name), {key, value})
    :ok
  end

  def fetch(name \\ __MODULE__, key) do
    {:ok, :ets.lookup_element(tab_name(name), key, 2)}
  rescue
    ArgumentError -> :miss
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(name) do
    table = new_table(name)
    schedule_clear()
    {:ok, %{name: name, table: table}}
  end

  def handle_info(:clear, state) do
    :ets.delete_all_objects(state.table)
    schedule_clear()
    {:noreply, state}
  end

  defp schedule_clear do
    Process.send_after(self(), :clear, @clear_interval)
  end

  defp new_table(name) do
    name
    |> tab_name()
    |> :ets.new([:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
  end

  defp tab_name(name), do: :"#{name}_cache"
end
