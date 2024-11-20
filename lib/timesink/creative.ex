defmodule Timesink.Creative do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          first_name: :string,
          last_name: :string,
          user: Timesink.Accounts.User.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "creative" do
    belongs_to :user, Timesink.Accounts.User

    field :first_name, :string
    field :last_name, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(creative :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> cast_assoc(:user, required: true, with: &Timesink.Accounts.User.changeset/2)
    |> validate_length(:first_name, min: 2)
    |> validate_length(:last_name, min: 2)
  end
end
