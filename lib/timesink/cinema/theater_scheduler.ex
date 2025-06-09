defmodule Timesink.Cinema.TheaterScheduler do
  use GenServer
  require Logger

  alias Timesink.Cinema.{Exhibition, Showcase, PlaybackState}
  alias Timesink.Repo

  import Ecto.Query

  @tick_interval 1_000
  @ets_table :theater_schedule_cache

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@ets_table, [:named_table, :public, :set])
    preload_into_ets()
    schedule_tick()
    {:ok, %{previous_states: %{}}}
  end

  def handle_info(:tick, state) do
    new_state =
      :ets.tab2list(@ets_table)
      |> Enum.reduce(state.previous_states, fn {theater_id,
                                                %{
                                                  exhibition: ex,
                                                  duration: duration,
                                                  showcase: showcase
                                                }},
                                               acc ->
        playback_state =
          case current_offset_for(ex.theater, showcase, duration) do
            {:upcoming, countdown} ->
              %PlaybackState{
                phase: :upcoming,
                countdown: countdown,
                offset: nil,
                theater_id: theater_id
              }

            {:playing, offset} ->
              %PlaybackState{
                phase: :playing,
                countdown: nil,
                offset: offset,
                theater_id: theater_id
              }

            {:intermission, countdown} ->
              %PlaybackState{
                phase: :intermission,
                countdown: countdown,
                offset: nil,
                theater_id: theater_id
              }

            nil ->
              Logger.warning("No valid offset for theater #{theater_id}")
              nil
          end

        if playback_state do
          prev = Map.get(acc, theater_id)

          maybe_broadcast_phase_change(prev, playback_state)
          broadcast_tick(playback_state)

          Map.put(acc, theater_id, playback_state)
        else
          acc
        end
      end)

    schedule_tick()
    {:noreply, %{state | previous_states: new_state}}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  def current_offset_for(theater, showcase, film_duration_secs) do
    with %NaiveDateTime{} = naive <- showcase.start_at do
      interval = theater.playback_interval_minutes * 60
      now = DateTime.utc_now()

      adjusted_anchor =
        showcase.start_at
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.add(theater.start_offset_minutes * 60)

      case DateTime.compare(now, adjusted_anchor) do
        :lt ->
          {:upcoming, DateTime.diff(adjusted_anchor, now)}

        _ ->
          seconds_since_anchor = DateTime.diff(now, adjusted_anchor)
          cycles_elapsed = div(seconds_since_anchor, interval)
          cycle_start = DateTime.add(adjusted_anchor, cycles_elapsed * interval)
          offset = DateTime.diff(now, cycle_start)

          cond do
            offset < film_duration_secs -> {:playing, offset}
            offset < interval -> {:intermission, interval - offset}
            true -> {:intermission, interval}
          end
      end
    else
      _ ->
        Logger.warning("Missing or invalid showcase.start_at for theater #{inspect(theater.id)}")
        nil
    end
  end

  def get_playback_state(theater, showcase, duration) do
    case current_offset_for(theater, showcase, duration) do
      {:upcoming, countdown} ->
        %PlaybackState{
          phase: :upcoming,
          countdown: countdown,
          offset: nil,
          theater_id: theater.id
        }

      {:playing, offset} ->
        %PlaybackState{
          phase: :playing,
          countdown: nil,
          offset: offset,
          theater_id: theater.id
        }

      {:intermission, countdown} ->
        %PlaybackState{
          phase: :intermission,
          countdown: countdown,
          offset: nil,
          theater_id: theater.id
        }

      nil ->
        nil
    end
  end

  def preload_into_ets do
    :ets.delete_all_objects(@ets_table)

    case Showcase.get_by(%{status: :active}) do
      {:ok, showcase} ->
        exhibitions =
          Exhibition
          |> where([e], e.showcase_id == ^showcase.id)
          |> preload([:theater, film: [video: [:blob]]])
          |> Repo.all()

        for exhibition <- exhibitions do
          duration = Timesink.Cinema.get_film_duration_seconds(exhibition.film)

          Logger.info(
            "Preloading exhibition #{exhibition.id} into ETS for theater #{exhibition.theater_id} with duration #{duration} seconds"
          )

          :ets.insert(@ets_table, {
            exhibition.theater_id,
            %{exhibition: exhibition, showcase: showcase, duration: duration}
          })
        end

      _ ->
        Logger.warning("No active showcase found — ETS preload skipped")
        :ok
    end
  end

  def handle_cast(:reload, state) do
    preload_into_ets()
    {:noreply, state}
  end

  def reload, do: GenServer.cast(__MODULE__, :reload)

  ## ───── Phase Change Broadcasting ─────

  def maybe_broadcast_phase_change(nil, %PlaybackState{} = current),
    do: broadcast_phase_change(current)

  def maybe_broadcast_phase_change(
        %PlaybackState{phase: prev_phase},
        %PlaybackState{phase: curr_phase} = current
      )
      when prev_phase != curr_phase,
      do: broadcast_phase_change(current)

  def maybe_broadcast_phase_change(_, _), do: :noop

  defp broadcast_phase_change(%PlaybackState{} = state) do
    Phoenix.PubSub.broadcast(
      Timesink.PubSub,
      "theater:#{state.theater_id}",
      %{event: "phase_change", playback_state: state}
    )
  end

  ## ───── Tick Broadcasting ─────

  defp broadcast_tick(%PlaybackState{} = state) do
    Phoenix.PubSub.broadcast(
      Timesink.PubSub,
      "scheduler:#{state.theater_id}",
      %{event: "tick", playback_state: state}
    )
  end
end
