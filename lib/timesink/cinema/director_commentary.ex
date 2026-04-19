defmodule Timesink.Cinema.DirectorCommentary do
  alias Timesink.Cinema.{Film, FilmCreative}
  alias Timesink.Repo
  import Ecto.Query

  @doc """
  Returns true if the given user is a verified director of the film identified by film_id.

  Verification requires:
  - The user has a claimed (approved) creative profile (creative.user_id == user.id)
  - That creative has a film_creative record with role :director for the given film
  """
  @spec director_of_film?(user :: map(), film_id :: binary()) :: boolean()
  def director_of_film?(user, film_id) do
    FilmCreative
    |> join(:inner, [fc], c in assoc(fc, :creative))
    |> where(
      [fc, c],
      fc.film_id == ^film_id and
        fc.role == :director and
        c.user_id == ^user.id
    )
    |> Repo.exists?()
  end

  @doc """
  Returns all films for which the given user is a verified director.
  Used to populate the director's private dashboard.
  """
  @spec list_director_films(user :: map()) :: [Film.t()]
  def list_director_films(user) do
    Film
    |> join(:inner, [f], fc in FilmCreative, on: fc.film_id == f.id)
    |> join(:inner, [_f, fc], c in assoc(fc, :creative))
    |> where([_f, fc, c], fc.role == :director and c.user_id == ^user.id)
    |> Repo.all()
    |> Repo.preload(directors: [creative: :user])
  end
end
