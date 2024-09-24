defmodule Timesink.Accounts.Profile do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset
  alias Timesink.Accounts

  @type t :: %{
          __struct__: __MODULE__,
          user_id: integer(),
          birthdate: Date.t(),
          location: map(),
          org_name: String.t(),
          org_position: String.t(),
          bio: String.t()
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "profiles" do
    belongs_to :user, Accounts.User

    field :birthdate, :date
    field :location, :map
    field :org_name, :string
    field :org_position, :string
    field :bio, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(profile :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [
      :user_id,
      :user,
      :birthdate,
      :location,
      :org_name,
      :org_position,
      :bio
    ])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
  end
end
