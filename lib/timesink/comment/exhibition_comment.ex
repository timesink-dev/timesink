defmodule Timesink.Comment.Exhibition do
  import Ecto.Query, warn: false
  alias Timesink.Repo
  alias Timesink.Comment

  @exhibition_source "exhibition_comment"

  def list_recent_exhibition_comments(exhibition_id) do
    from(c in {@exhibition_source, Comment},
      where: c.assoc_id == ^exhibition_id,
      order_by: [asc: c.inserted_at]
    )
    |> preload(:user)
    |> Repo.all()
  end

  def create_exhibition_comment!(attrs) do
    %Comment{}
    |> Ecto.put_meta(source: @exhibition_source)
    # your abstract validations
    |> Comment.changeset(attrs)
    |> Repo.insert!()
    |> Repo.preload(:user)
  end
end
