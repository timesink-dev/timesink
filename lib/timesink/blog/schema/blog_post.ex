defmodule Timesink.BlogPost do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  alias Timesink.Comment

  @type t :: %{
          __struct__: __MODULE__,
          title: :string,
          content: :string,
          author: :string,
          slug: :string,
          published_at: :utc_datetime
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "blog_post" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :author, :string
    field :published_at, :utc_datetime

    has_many :comments, {"blog_post_comment", Comment}, foreign_key: :assoc_id

    timestamps(type: :utc_datetime)
  end

  def changeset(blog, params) do
    blog
    |> cast(params, [:title, :slug, :content, :author, :published_at])
    |> validate_required([:title, :slug, :content, :author])
    |> validate_length(:title, min: 1)
    |> validate_length(:content, min: 1)
  end
end
