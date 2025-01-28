defmodule Timesink.Auth do
  @moduledoc """
  The Auth context.
  """

  import Ecto.Changeset
  # import Ecto.Query, warn: false
  alias Timesink.Accounts.User
  alias Phoenix.Token

  # Change this to your own secret
  @token_salt "user_auth_salt"
  # 7 days in seconds
  @max_age 7 * 24 * 60 * 60

  def generate_token(user) do
    Token.sign(TimesinkWeb.Endpoint, @token_salt, %{user_id: user.id, role: user.roles})
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
      token = generate_token(user)
      IO.inspect(token, label: "token in authenticate")
      {:ok, user, token}
    end

    # else
    #   _ -> {:error, :invalid_credentials}
  end

  def verify_token(token) do
    Token.verify(TimesinkWeb.Endpoint, @token_salt, token, max_age: @max_age)
  end

  # @spec token_auth(token_or_claims :: String.t() | %{}) ::
  #         {:ok, User.t(), Guardian.Token.claims()} | {:error, :bad_credentials}
  def token_auth(token) when is_binary(token) do
    with {:ok, claims} <- verify_token(token) do
      # token_auth(claims)
    else
      _error ->
        # TODO: log error
        {:error, :bad_credentials}
    end
  end

  def token_auth(claims) when is_map(claims) do
    with {:ok, :not_bad} <- BadToken.verify(claims),
         {:ok, user} <- User.get(claims["sub"]) do
      {:ok, user, claims}
    else
      _error ->
        # TODO: log error
        {:error, :bad_credentials}
    end
  end
end
