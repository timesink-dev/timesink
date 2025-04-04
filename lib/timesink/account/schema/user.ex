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
    has_many :tokens, Timesink.Token

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(email username first_name last_name password)a

  def changeset(struct, params, _metadata) do
    changeset(struct, params)
  end

  @spec changeset(user :: %__MODULE__{}, params :: %{optional(key :: atom()) => term()}) ::
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
    |> cast_assoc(:profile,
      required: true,
      with: &Accounts.Profile.changeset/2,
      message: "Profile is required"
    )
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email, message: "Email already exists")
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters")
    |> validate_length(:first_name, min: 1)
    |> validate_length(:last_name, min: 1)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]{3,32}$/, message: "Invalid username format")
    |> unique_constraint(:username, message: "Username is already taken")
    |> validate_length(:username, min: 3)
  end

  def email_password_changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/, message: "Invalid email format")
    |> unique_constraint(:email, message: "Email already exists")
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters")
  end

  def name_changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1)
    |> validate_length(:last_name, min: 1)
  end

  def username_changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 32)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]{3,32}$/, message: "Invalid username format")
    |> unique_constraint(:username, message: "Username is already taken")
  end

  def location_changeset(%Accounts.Profile{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:location])
    |> cast_embed(:location, with: &Accounts.Location.changeset/2)
    |> validate_required([:location])
  end

  @doc """
  Validates the User's credentials
  Both `email` and `password` are required
  Uses the email to confirm existence of User, and then validates the password
  """
  @spec check_credentials(params :: %{email: String.t(), password: String.t()}) ::
          {:ok, User.t()} | {:error, :invalid_credentials}
  def check_credentials(%{} = params) do
    changeset =
      {%{}, %{email: :string, password: :string}}
      |> cast(params, [:email, :password])
      |> validate_required([:email, :password])

    with {:ok, params} <- apply_action(changeset, :password_auth),
         {:ok, user} <- User.get_by(email: params.email),
         {:ok, user} <- valid_password?(user, params.password) do
      {:ok, user}
    else
      {:error, :not_found} -> {:error, :invalid_credentials}
      {:error, _} -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Verifies the password.
  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{password: password_hash} = user, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    with true <- Argon2.verify_pass(password, password_hash) do
      {:ok, user}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  def valid_password?(_, _), do: Argon2.no_user_verify()
end
