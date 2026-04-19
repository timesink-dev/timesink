defmodule Timesink.Cinema.Film.Note do
  alias Timesink.Cinema.Note
  alias Timesink.Repo
  import Ecto.Query

  @spec list_commentary(film_id :: binary()) :: [Note.t()]
  def list_commentary(film_id) do
    Note
    |> where([n], n.film_id == ^film_id and n.source == :director and n.status == :visible)
    |> order_by([n], asc: n.offset_seconds)
    |> preload([:user])
    |> Repo.all()
  end

  @spec list_commentary(film_id :: binary(), current_offset :: integer()) :: [Note.t()]
  def list_commentary(film_id, current_offset) do
    Note
    |> where(
      [n],
      n.film_id == ^film_id and
        n.source == :director and
        n.status == :visible and
        n.offset_seconds <= ^current_offset
    )
    |> order_by([n], asc: n.offset_seconds)
    |> preload([:user])
    |> Repo.all()
  end

  @spec create_commentary(user :: map(), film_id :: binary(), params :: map()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def create_commentary(user, film_id, params) do
    %Note{}
    |> Note.changeset(
      Map.merge(params, %{
        source: :director,
        user_id: user.id,
        film_id: film_id
      })
    )
    |> Repo.insert()
  end

  @spec update_commentary(note :: Note.t(), params :: map()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def update_commentary(note, params) do
    note
    |> Note.changeset(params)
    |> Repo.update()
  end

  @spec delete_commentary(note :: Note.t()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def delete_commentary(note) do
    Repo.delete(note)
  end
end
