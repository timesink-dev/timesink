defmodule Timesink.Cinema do
  @moduledoc """
  The Cinema context.
  """

  alias Timesink.Cinema.{Film, Showcase, Theater, Exhibition, PlaybackState}

  alias Timesink.Repo
  import Ecto.Query
  require Logger

  @doc """
  Create a film.

  ## Examples

      iex> create_film(%{
        "title" => "The Matrix",
        "duration" => 136
      })
      {:ok, %Timesink.Cinema.Film{…}}
  """
  @spec create_film(params :: map()) ::
          {:ok, Film.t()} | {:error, Ecto.Changeset.t()}
  def create_film(params) do
    with {:ok, film} <-
           Film.create(params) do
      {:ok, film}
    end
  end

  @doc """
  Create a showcase.

  ## Examples

      iex> create_showcase(%{
        "title" => "The Matrix",
        "description" => "A showcase of The Matrix",
        "start_at" => ~U[2021-08-01 00:00:00Z],
        "end_at" => ~U[2021-08-01 00:00:00Z],
        "status" => :active
      })
      {:ok, %Timesink.Cinema.Showcase{…}}
  """
  @spec create_showcase(params :: map()) ::
          {:ok, Showcase.t()} | {:error, Ecto.Changeset.t()}
  def create_showcase(params) do
    with {:ok, showcase} <-
           Showcase.create(params) do
      {:ok, showcase}
    end
  end

  @doc """
  Create a theater.

  ## Examples

      iex> create_theater(%{"name" => "The Matrix", "location" => "A showcase of The Matrix", "seats" => 100})
      {:ok, %Timesink.Cinema.Theater{…}}
  """
  @spec create_theater(params :: map()) ::
          {:ok, Theater.t()} | {:error, Ecto.Changeset.t()}
  def create_theater(params) do
    with {:ok, theater} <-
           Theater.create(params) do
      {:ok, theater}
    end
  end

  @doc """
  Create exhibition.

  ## Examples

      iex> create_exhibition(%{
        "film_id" => film.id,
        "showcase_id" => showcase.id,
        "theater_id" => theater.id
      })
      {:ok, %Timesink.Cinema.Exhibition{…}}
  """
  @spec create_exhibition(params :: map()) ::
          {:ok, Exhibition.t()} | {:error, Ecto.Changeset.t()}
  def create_exhibition(params) do
    with {:ok, exhibition} <-
           Exhibition.create(params) do
      {:ok, exhibition}
    end
  end

  def list_showcases_with_theaters do
    Timesink.Repo.all(
      from s in Showcase,
        preload: [exhibitions: [:theater]]
    )
  end

  def list_active_showcase_theaters do
    Timesink.Repo.all(
      from s in Showcase,
        where: s.status == :active,
        preload: [exhibitions: [:theater]]
    )
  end

  def get_active_showcase_with_exhibitions do
    Showcase |> where([s], s.status == :active) |> preload([:exhibitions]) |> Timesink.Repo.one()
  end

  @doc """
  Preloads all relevant associations for a list of exhibitions.
  """
  def preload_exhibitions(exhibitions) do
    Repo.preload(exhibitions, [
      :theater,
      film: [
        :genres,
        :writers,
        :producers,
        :crew,
        video: [:blob],
        poster: [:blob],
        trailer: [:blob],
        directors: [:creative],
        cast: [:creative]
      ]
    ])
  end

  def current_screening_start(%Exhibition{showcase: showcase, theater: theater}) do
    interval_seconds = theater.playback_interval_minutes * 60
    now = DateTime.utc_now()
    seconds_since_anchor = DateTime.diff(now, showcase.start_at)
    cycles_elapsed = div(seconds_since_anchor, interval_seconds)

    DateTime.add(showcase.start_at, cycles_elapsed * interval_seconds)
  end

  def playback_offset_seconds(exhibition) do
    now = DateTime.utc_now()
    start = current_screening_start(exhibition)
    DateTime.diff(now, start)
  end

  def compute_initial_playback_states(exhibitions, showcase) do
    Enum.reduce(exhibitions, %{}, fn exhibition, acc ->
      duration = get_film_duration_seconds(exhibition.film)

      case Timesink.Cinema.TheaterScheduler.get_playback_state(
             exhibition.theater,
             showcase,
             duration
           ) do
        %PlaybackState{} = state ->
          Map.put(acc, exhibition.theater_id, state)

        _ ->
          acc
      end
    end)
  end

  # Correct pattern for a video with blob
  def get_film_duration_seconds(%{video: %{blob: %{metadata: %{"duration_sec" => secs}}}}) do
    secs
  end

  def get_film_duration_seconds(%{duration: minutes}) when is_integer(minutes),
    do: minutes

  # default fallback
  def get_film_duration_seconds(_film) do
    Logger.warning("Film duration not found, returning 0 seconds")
    0
  end
end
