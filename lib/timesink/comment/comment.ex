defmodule Timesink.Comment do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          content: :string,
          user_id: Ecto.UUID.t(),
          user: Timesink.Account.User.t(),
          assoc_id: Ecto.UUID.t(),
          parent: Timesink.Comment.t() | nil,
          parent_id: Ecto.UUID.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "abstract table: comment" do
    field :content, :string
    field :assoc_id, :binary_id

    # the author of the comment
    belongs_to :user, Timesink.Account.User

    # Optional parent for threading (1-level replies)
    belongs_to :parent, __MODULE__

    timestamps(type: :utc_datetime)
  end

  def changeset(%{__struct__: __MODULE__} = comment, %{} = params) do
    comment
    |> cast(params, [:content, :assoc_id, :user_id, :parent_id])
    |> validate_required([:content, :assoc_id, :user_id])
    |> validate_length(:content, min: 1)
    |> foreign_key_constraint(:assoc_id)
    |> assoc_constraint(:user)
    |> assoc_constraint(:parent)
  end
end
