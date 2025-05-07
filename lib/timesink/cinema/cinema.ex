defmodule Timesink.Cinema do
  @moduledoc """
  The Cinema context.
  """

  alias Timesink.Cinema.Film
  alias Timesink.Cinema.Showcase
  alias Timesink.Cinema.Theater
  alias Timesink.Cinema.Exhibition
  import Ecto.Query

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

  def get_theater_by_slug(slug) do
    case Timesink.Repo.get_by(Theater, slug: slug) do
      nil -> {:error, :not_found}
      theater -> {:ok, theater}
    end
  end

  def get_active_showcase() do
    Timesink.Repo.get_by(Showcase, status: :active)
    |> case do
      nil -> {:error, :no_active_showcase}
      s -> {:ok, s}
    end
  end

  def get_exhibition_for_theater_and_showcase(theater_id, showcase_id) do
    Timesink.Repo.get_by(Exhibition, theater_id: theater_id, showcase_id: showcase_id)
    |> case do
      nil -> {:error, :no_exhibition}
      e -> {:ok, e}
    end
  end

  def get_film_by_id(id) do
    Timesink.Repo.get(Film, id)
    |> case do
      nil -> {:error, :not_found}
      f -> {:ok, f}
    end
  end
end
