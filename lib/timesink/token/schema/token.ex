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

  @type status :: :valid | :invalid
  @status [:valid, :invalid]
  @doc """
  Token status can be one of the following:
  * :valid – The token is active and can be used, but it may expire based on expires_at.
  * :invalid – The token has already been used or was explicitly invalidated (e.g., a new token was issued, making the old one obsolete).
  """
  def status, do: @status

  @type token :: %{
          __struct__: __MODULE__,
          kind: kind(),
          secret: String.t(),
          status: status(),
          expires_at: DateTime.t(),
          user_id: Ecto.UUID.t(),
          user: User.t(),
          waitlist_id: Ecto.UUID.t(),
          waitlist: Applicant.t(),
          email: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "token" do
    field :kind, Ecto.Enum, values: @kind

    # the secret field is the actual token value
    field :secret, :string, redact: true

    field :status, Ecto.Enum, values: @status, default: :valid
    field :expires_at, :utc_datetime

    # for onboarding applicants (email verification - they don't have a user account yet, and may not have a waitlist entry)
    field :email, :string

    belongs_to :user, User
    belongs_to :waitlist, Applicant
    timestamps(type: :utc_datetime)
  end

  @spec changeset(token :: token(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:kind, :secret, :status, :expires_at, :user_id, :waitlist_id, :email])
    |> validate_required([:kind, :secret, :status, :expires_at])
    |> unique_constraint(:secret, message: "Token already exists")
  end

  def is_valid?(token) do
    with {:ok, fetched_token} <- get(token.id) do
      fetched_token.status == :valid && !token_expired?(fetched_token)
    else
      _ -> false
    end
  end

  def token_expired?(token) do
    token.expires_at && DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt
  end

  def validate_invite(token) do
    with {:ok, token} <- Timesink.Token.get_by(secret: token, status: :valid) do
      {:ok, token}
    else
      _ -> {:error, :invalid}
    end
  end

  def invalidate_token(token) do
    update(token, %{
      status: :invalid
    })
  end
end
