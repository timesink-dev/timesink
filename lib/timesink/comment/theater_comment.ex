defmodule Timesink.Comment.Theater do
  import Ecto.Query, warn: false
  alias Timesink.Repo
  alias Timesink.Comment

  @theater_source "theater_comment"

  def list_recent_theater_comments(theater_id, limit \\ 100) do
    from(c in {@theater_source, Comment},
      where: c.assoc_id == ^theater_id,
      order_by: [asc: c.inserted_at],
      limit: ^limit
    )
    |> preload(:user)
    |> Repo.all()
  end

  def create_theater_comment!(attrs) do
    %Comment{}
    |> Ecto.put_meta(source: @theater_source)
    # your abstract validations
    |> Comment.changeset(attrs)
    |> Repo.insert!()
    |> Repo.preload(:user)
  end
end
