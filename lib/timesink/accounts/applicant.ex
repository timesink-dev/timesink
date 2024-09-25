defmodule Timesink.Accounts.Applicant do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          email: String.t(),
          status: atom()
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "waitlists" do
    field :email, :string
    # pending - default status
    # invited - The person has received an invite code, but they haven’t signed up yet.
    # processed - The person has successfully signed up by using the invite code, and is now a user.
    field :status, Ecto.Enum, values: [:pending, :invited, :processed], default: :pending

    belongs_to :invite_code, Timesink.Accounts.InviteCode

    timestamps(type: :utc_datetime)
  end

  @spec changeset(applicant :: t(), params :: %{optional(key :: atom()) => value :: term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct_: __MODULE__} = struct, params) do
    struct
    |> cast(params, [:email, :status])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
  end
end
