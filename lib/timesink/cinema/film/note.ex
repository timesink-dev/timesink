defmodule Timesink.Cinema.Film.Note do
  alias Timesink.Cinema.Note
  alias Timesink.Repo
  import Ecto.Query

  @spec list_commentary(film_id :: binary()) :: [Note.t()]
  def list_commentary(film_id) do
    Note
    |> where([n], n.film_id == ^film_id and n.source == :director and n.status == :visible)
    |> order_by([n], asc: n.offset_seconds, asc: n.inserted_at)
    |> preload(user: :creative)
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
    |> order_by([n], asc: n.offset_seconds, asc: n.inserted_at)
    |> preload(user: :creative)
    |> Repo.all()
  end

  @spec next_commentary_preview(film_id :: binary(), current_offset :: integer()) ::
          %{offset_seconds: integer(), body: String.t(), username: String.t() | nil} | nil
  def next_commentary_preview(film_id, current_offset) do
    note =
      Note
      |> where(
        [n],
        n.film_id == ^film_id and
          n.source == :director and
          n.status == :visible and
          n.offset_seconds > ^current_offset
      )
      |> order_by([n], asc: n.offset_seconds)
      |> limit(1)
      |> preload(user: :creative)
      |> Repo.one()

    if note do
      %{
        offset_seconds: note.offset_seconds,
        body: note.body,
        username: note.user && note.user.username
      }
    else
      nil
    end
  end

  @spec create_commentary(user :: map(), film_id :: binary(), params :: map()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def create_commentary(user, film_id, params) do
    Note.create(
      Map.merge(params, %{
        source: :director,
        user_id: user.id,
        film_id: film_id
      })
    )
  end
end
