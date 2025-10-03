defmodule Timesink.Account.User do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Account
  alias Timesink.Account.User

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
          unverified_email: String.t(),
          profile: Account.Profile.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "user" do
    field :is_active, :boolean, default: true
    field :email, :string
    field :password, :string, redact: true
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :unverified_email, :string

    field :roles, {:array, Ecto.Enum}, values: @roles, default: [], redact: true

    has_one :profile, Account.Profile
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
      :roles,
      :unverified_email
    ])
    |> cast_assoc(:profile,
      required: true,
      with: &Account.Profile.changeset/2,
      message: "Profile is required"
    )
    |> trim_fields([:email, :username, :first_name, :last_name])
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:unverified_email, ~r/@/)
    |> unique_constraint(:email, message: "Email already exists")
    |> unique_constraint(:unverified_email, message: "Email already exists")
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
    |> trim_fields([:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/, message: "Invalid email format")
    |> unique_constraint(:email, message: "Email already exists")
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters")
  end

  def name_changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:first_name, :last_name])
    |> trim_fields([:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1)
    |> validate_length(:last_name, min: 1)
    |> validate_format(:first_name, ~r/^[\p{L}\p{M}' -]+$/u,
      message: "First name contains invalid characters, i.e. @, #, $, %, etc. are not allowed."
    )
    |> validate_format(:last_name, ~r/^[\p{L}\p{M}' -]+$/u,
      message: "Last name contains invalid characters. i.e. @, #, $, %, etc. are not allowed."
    )
  end

  def password_only_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:password])
    |> trim_fields([:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters")
  end

  def username_changeset(%{__struct__: __MODULE__} = struct, params \\ %{}) do
    struct
    |> cast(params, [:username])
    |> trim_fields([:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 32)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]{3,32}$/,
      message:
        "Invalid username format. Special characters like @, #, $, %, etc. are not allowed."
    )
    |> unique_constraint(:username, message: "Username is already taken")
  end

  def location_changeset(%Account.Profile{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:location])
    |> cast_embed(:location, with: &Account.Location.changeset/2)
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

  defp trim_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      update_change(acc, field, fn val -> String.trim(val || "") end)
    end)
  end
end
