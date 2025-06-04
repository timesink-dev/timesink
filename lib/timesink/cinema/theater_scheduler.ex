defmodule Timesink.Cinema.TheaterScheduler do
  use GenServer
  require Logger

  alias Timesink.Cinema.{Theater, Exhibition, Showcase}
  alias Timesink.Repo

  @tick_interval 1_000

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    Enum.each(Repo.all(Theater), fn theater ->
      with {:ok, showcase} <- Showcase.get_by(%{status: :active}),
           {:ok, exhibition} <-
             Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}) do
        offset = compute_offset(showcase, theater)

        Logger.debug("Broadcasting offset=#{offset} for theater=#{theater.id}")

        Phoenix.PubSub.broadcast(
          Timesink.PubSub,
          "theater:#{theater.id}",
          %{event: "tick", offset: offset, interval: theater.playback_interval_minutes * 60}
        )
      end
    end)

    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp compute_offset(showcase, theater) do
    with %NaiveDateTime{} = naive <- showcase.start_at do
      interval = theater.playback_interval_minutes * 60
      now = DateTime.utc_now()
      anchor = DateTime.from_naive!(naive, "Etc/UTC")

      case DateTime.compare(now, anchor) do
        :lt ->
          DateTime.diff(now, anchor)

        _ ->
          seconds_since_anchor = DateTime.diff(now, anchor)
          cycles_elapsed = div(seconds_since_anchor, interval)
          cycle_start = DateTime.add(anchor, cycles_elapsed * interval)
          DateTime.diff(now, cycle_start)
      end
    else
      _ ->
        Logger.warning("Missing or invalid showcase.start_at for theater #{theater.id}")
        nil
    end
  end
end
