defmodule Timesink.Cinema.Exhibition.Note do
  alias Timesink.Cinema.{Note}

  alias Timesink.Repo
  import Ecto.Query

  def list_visible_notes(exhibition_id, current_offset) do
    Note
    |> where(
      [n],
      n.exhibition_id == ^exhibition_id and
        n.offset_seconds <= ^current_offset and
        n.status == :visible
    )
    |> order_by([n], asc: n.offset_seconds)
    |> preload([:user])
    |> Repo.all()
  end

  def total_notes_count(exhibition_id) do
    Note
    |> where([n], n.exhibition_id == ^exhibition_id and n.status == :visible)
    |> Repo.aggregate(:count, :id)
  end

  def next_note_offset(exhibition_id, current_offset) do
    Note
    |> where(
      [n],
      n.exhibition_id == ^exhibition_id and
        n.offset_seconds > ^current_offset and
        n.status == :visible
    )
    |> order_by([n], asc: n.offset_seconds)
    |> select([n], n.offset_seconds)
    |> limit(1)
    |> Repo.one()
  end

  def next_note_preview(exhibition_id, current_offset) do
    note =
      Note
      |> where(
        [n],
        n.exhibition_id == ^exhibition_id and
          n.offset_seconds > ^current_offset and
          n.status == :visible
      )
      |> order_by([n], asc: n.offset_seconds)
      |> limit(1)
      |> preload([:user])
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
end
