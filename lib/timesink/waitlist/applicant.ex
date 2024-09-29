defmodule Timesink.Waitlist.Applicant do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          status: atom()
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "waitlist" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :status, Ecto.Enum, values: [:pending, :invited, :completed], default: :pending

    timestamps(type: :utc_datetime)
  end

  @spec changeset(applicant :: t(), params :: %{optional(key :: atom()) => value :: term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct_: __MODULE__} = struct, params) do
    struct
    |> cast(params, [:email, :status, :first_name, :last_name])
    |> validate_required([:email, :first_name, :last_name])
    |> validate_format(:email, ~r/@/)
  end
end
