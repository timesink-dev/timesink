defmodule Timesink.Accounts.User do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Accounts

  @roles [:admin, :creator]

  @type t :: %{
          __struct__: __MODULE__,
          is_active: boolean(),
          email: String.t(),
          password_hash: String.t(),
          username: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          roles: list(String.t()),
          profile: Accounts.Profile.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "user" do
    field :is_active, :boolean, default: true
    field :email, :string
    field :password_hash, :string, redact: true
    field :username, :string
    field :first_name, :string
    field :last_name, :string

    field :roles, {:array, Ecto.Enum}, values: @roles, default: [], redact: true

    has_one :profile, Accounts.Profile

    has_one :private_key, Timesink.Storage.Attachment,
      foreign_key: :target_id,
      where: [target_schema: :user, name: "private_key"]

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(email username first_name last_name)a

  def changeset(struct, params, _metadata) do
    changeset(struct, params)
  end

  @spec changeset(user :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [
      :is_active,
      :email,
      :password_hash,
      :username,
      :first_name,
      :last_name,
      :roles
    ])
    |> cast_assoc(:profile, required: true, with: &Accounts.Profile.changeset/2)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> validate_length(:first_name, min: 2)
    |> validate_length(:last_name, min: 2)
    |> validate_length(:username, min: 1)
  end
end
