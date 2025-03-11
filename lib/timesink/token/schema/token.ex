defmodule Timesink.Token do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Accounts.User
  alias Timesink.Waitlist.Applicant

  @type kind :: :invite | :email_verification | :password_reset
  @kind [:invite, :email_verification, :password_reset]
  def kind, do: @kind

  @type status :: :active | :used
  @status [:active, :used]
  def status, do: @status

  @type token :: %{
          __struct__: __MODULE__,
          kind: kind(),
          secret: String.t(),
          status: status(),
          expires_at: DateTime.t(),
          user_id: Ecto.UUID.t(),
          user: User.t(),
          applicant_id: Ecto.UUID.t(),
          applicant: Applicant.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "token" do
    field :kind, Ecto.Enum, values: @kind

    # the secret field is the actual token value
    field :secret, :string

    field :status, Ecto.Enum, values: @status, default: :active
    field :expires_at, :utc_datetime
    belongs_to :user, User
    belongs_to :applicant, Applicant
    timestamps(type: :utc_datetime)
  end

  @spec changeset(token :: token(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:kind, :secret, :status, :expires_at, :user_id, :applicant_id])
    |> validate_required([:kind, :secret, :status, :expires_at])
    |> unique_constraint(:secret, message: "Token already exists")
  end
end
