defmodule Timesink.Cinema.TheaterScheduler do
  use GenServer
  require Logger

  alias Timesink.Cinema.{Theater, Exhibition, Showcase}
  alias Timesink.Repo

  import Ecto.Query

  @tick_interval 1_000
  @ets_table :theater_schedule_cache

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    # Create ETS table if not exists
    :ets.new(@ets_table, [:named_table, :public, :set])

    preload_into_ets()

    schedule_tick()
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    :ets.tab2list(@ets_table)
    |> Enum.each(fn {theater_id, %{exhibition: ex, duration: duration, showcase: showcase}} ->
      case current_offset_for(ex.theater, showcase, duration) do
        {:before, countdown} ->
          Phoenix.PubSub.broadcast(
            Timesink.PubSub,
            "theater:#{theater_id}",
            %{
              event: "tick",
              playback_state: %{
                phase: :before,
                started: false,
                countdown: countdown,
                offset: nil,
                theater_id: theater_id
              }
            }
          )

        {:playing, offset} ->
          Phoenix.PubSub.broadcast(
            Timesink.PubSub,
            "theater:#{theater_id}",
            %{
              event: "tick",
              playback_state: %{
                phase: :playing,
                started: true,
                offset: offset,
                countdown: nil,
                theater_id: theater_id
              }
            }
          )

        {:intermission, countdown} ->
          Phoenix.PubSub.broadcast(
            Timesink.PubSub,
            "theater:#{theater_id}",
            %{
              event: "tick",
              playback_state: %{
                phase: :intermission,
                started: false,
                offset: nil,
                countdown: countdown,
                theater_id: theater_id
              }
            }
          )

        nil ->
          Logger.warning("No valid offset for theater #{theater_id}")
      end
    end)

    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  @doc """
  Calculate the current playback offset for a theater based on its playback interval and the showcase start time.
  """
  @spec current_offset_for(Theater.t(), Showcase.t(), integer()) ::
          {:before, pos_integer()}
          | {:playing, non_neg_integer()}
          | {:intermission, pos_integer()}
          | nil
  def current_offset_for(theater, showcase, film_duration_secs) do
    with %NaiveDateTime{} = naive <- showcase.start_at do
      interval = theater.playback_interval_minutes * 60
      now = DateTime.utc_now()
      anchor = DateTime.from_naive!(naive, "Etc/UTC")

      case DateTime.compare(now, anchor) do
        :lt ->
          {:before, DateTime.diff(anchor, now)}

        _ ->
          seconds_since_anchor = DateTime.diff(now, anchor)
          cycles_elapsed = div(seconds_since_anchor, interval)
          cycle_start = DateTime.add(anchor, cycles_elapsed * interval)
          offset = DateTime.diff(now, cycle_start)

          cond do
            offset < film_duration_secs ->
              {:playing, offset}

            offset < interval ->
              {:intermission, interval - offset}

            true ->
              # Fallback
              {:intermission, interval}
          end
      end
    else
      _ ->
        Logger.warning("Missing or invalid showcase.start_at for theater #{inspect(theater.id)}")
        nil
    end
  end

  @doc """
  Calculate the current playback offset for a theater based on its playback interval and the showcase start time.
  """
  @spec current_offset_for(Theater.t(), Showcase.t()) :: integer() | nil
  def current_offset_for(theater, showcase) do
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

  def current_offset_for(theater_id) do
    with {:ok, theater} <- Theater.get(theater_id),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}) do
      current_offset_for(theater, showcase)
    else
      _ -> nil
    end
  end

  defp preload_into_ets do
    :ets.delete_all_objects(@ets_table)

    case Showcase.get_by(%{status: :active}) do
      {:ok, showcase} ->
        exhibitions =
          Exhibition
          |> where([e], e.showcase_id == ^showcase.id)
          |> preload([:theater, film: [video: [:blob]]])
          |> Repo.all()

        for exhibition <- exhibitions do
          IO.inspect(exhibition.film, label: "Film for exhibition")
          duration = Timesink.Cinema.get_film_duration_seconds(exhibition.film)

          Logger.info(
            "Preloading exhibition #{exhibition.id} into ETS for theater #{exhibition.theater_id} with duration #{duration} seconds"
          )

          :ets.insert(@ets_table, {
            exhibition.theater_id,
            %{
              exhibition: exhibition,
              showcase: showcase,
              duration: duration
            }
          })
        end

      _ ->
        Logger.warning("No active showcase found — ETS preload skipped")
        :ok
    end
  end
end
