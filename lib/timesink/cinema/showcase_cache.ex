defmodule Timesink.Cinema.ShowcaseCache do
  @moduledoc """
  In-memory ETS cache for the active showcase with exhibitions.
  Reduces database load on homepage and now-playing pages.

  Cache is automatically busted when:
  - A showcase status changes
  - Exhibitions are modified
  - The active showcase changes

  TTL: 30 seconds (configurable)
  """
  use GenServer
  alias Timesink.Cinema
  require Logger

  @cache_key :active_showcase
  # 30 seconds
  @ttl_ms 30_000

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(_) do
    :ets.new(__MODULE__, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{}}
  end

  # ---------- Public API ----------

  @doc """
  Get the active showcase with all exhibitions preloaded.
  Uses cache with TTL, falling back to database if cache miss.
  """
  def get_active_showcase do
    case :ets.lookup(__MODULE__, @cache_key) do
      [{@cache_key, showcase, expires_at}] ->
        now = :erlang.system_time(:millisecond)

        if expires_at > now do
          showcase
        else
          load_and_cache_active_showcase()
        end

      _ ->
        load_and_cache_active_showcase()
    end
  end

  @doc """
  Bust the cache, forcing next request to hit the database.
  Call this when showcases or exhibitions are modified.
  """
  def bust do
    :ets.delete(__MODULE__, @cache_key)
    :ok
  end

  @doc """
  Refresh the cache immediately (useful after updates).
  """
  def refresh do
    bust()
    load_and_cache_active_showcase()
  end

  # ---------- Internal ----------

  defp load_and_cache_active_showcase do
    case Cinema.get_active_showcase_with_exhibitions() do
      nil ->
        nil

      showcase ->
        # Preload all exhibitions with associations
        exhibitions =
          (showcase.exhibitions || [])
          |> Cinema.preload_exhibitions()
          |> Enum.sort_by(& &1.theater.name, :asc)

        enriched_showcase = %{showcase | exhibitions: exhibitions}
        expires_at = :erlang.system_time(:millisecond) + @ttl_ms

        :ets.insert(__MODULE__, {@cache_key, enriched_showcase, expires_at})
        enriched_showcase
    end
  end
end
