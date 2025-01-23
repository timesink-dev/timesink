defmodule TimesinkWeb.Auth do
  alias Phoenix.Token
  alias Timesink.Accounts.User

  # Change this to your own secret
  @token_salt "user_auth_salt"
  # 1 day in seconds
  @max_age 86_400

  # Generate token for a user
  def generate_token(user) do
    Token.sign(TimeSinkWeb.Endpoint, @token_salt, %{id: user.id, role: user.role})
  end

  # Verify token
  def verify_token(token) do
    Token.verify(TimeSinkWeb.Endpoint, @token_salt, token, max_age: @max_age)
  end

  @doc """
  Authenticates a user by retrieving the user with the given email, and then verifying the password.

  ## Examples

      iex> authenticate("foo@example.com", "correct_password")
      %User{}

      iex> authenticate("foo@example.com", "invalid_password")
      nil

  """
  def authenticate(email, password)
      when is_binary(email) and is_binary(password) do
    user = User.get_by!(email: email)
    if User.valid_password?(user, password), do: user
  end
end
