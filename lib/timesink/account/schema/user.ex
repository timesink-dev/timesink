defmodule Timesink.Accounts.User do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Accounts
  alias Timesink.Accounts.User

  @roles [:admin, :creator]

  @type t :: %{
          __struct__: __MODULE__,
          is_active: boolean(),
          email: String.t(),
          password: String.t(),
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
    field :password, :string, redact: true
    field :username, :string
    field :first_name, :string
    field :last_name, :string

    field :roles, {:array, Ecto.Enum}, values: @roles, default: [], redact: true

    has_one :profile, Accounts.Profile

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(email username first_name last_name password)a

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
      :password,
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

  # - [x] Fn to authenticate w/ user/pass; return user info & token
  # - [ ] Fn to authenticate w/ token; return user info

  @doc """
  Authenticates a user by retrieving the user with the given email, and then verifying the password.

  ## Examples

      iex> authenticate("foo@example.com", "correct_password")
      %User{}

      iex> authenticate("foo@example.com", "invalid_password")
      nil

  """
  @spec authenticate(%{email: binary(), password: binary()}) ::
          {:ok, user :: User.t(), token :: binary()} | {:error, term()}
  def authenticate(params) do
    email = params["email"]
    password = params["password"]

    with {:ok, user} <- password_auth(%{email: email, password: password}) do
      IO.inspect(user, label: "user in authenticate")
      {:ok, user}
    end

    # else
    #   _ -> {:error, :invalid_credentials}
  end

  @spec password_auth(params :: %{email: String.t(), password: String.t()}) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t() | term()}
  def password_auth(%{} = params) do
    changeset =
      {%{}, %{email: :string, password: :string}}
      |> cast(params, [:email, :password])
      |> validate_required([:email, :password])

    IO.inspect(params, label: "params in password_auth")
    IO.inspect(changeset, label: "changeset in password_auth")
    # {:ok, user} = User.get_by(email: params.email)

    with {:ok, params} <- apply_action(changeset, :password_auth),
         {:ok, user} <- User.get_by(email: params.email),
         true <- User.valid_password?(user, params.password) do
      IO.inspect(user, label: "user in password_auth")
      {:ok, user}
    end
  end

  @doc """
  Verifies the password.
  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Timesink.Accounts.User{password: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Argon2.verify_pass(password, password_hash)
  end

  def valid_password?(_, _), do: Argon2.no_user_verify()
end
