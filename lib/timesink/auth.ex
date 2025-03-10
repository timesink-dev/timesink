defmodule Timesink.Auth do
  @moduledoc """
  The core authentication context for Timesink.

  This module is responsible for generating and verifying authentication tokens.
  Its functions are independent of the web layer so that they can be used in different contexts,
  such as API endpoints, background jobs, or tests.

  ## Functions

    - `generate_token/1`: Generates a signed token with the user's id and roles.
    - `verify_token/1`: Verifies a token against its signature and expiry.
    - `token_auth/1`: A helper that verifies a token and returns its claims.
  """

  alias Phoenix.Token
  use TimesinkWeb, :verified_routes

  @token_salt System.get_env("AUTH_TOKEN_SALT")

  # 7 days
  @max_age 7 * 60 * 24 * 60

  @doc """
  Generates a signed token for the given user.

  The token includes the user's id and roles.
  """
  def generate_token(user) do
    Token.sign(TimesinkWeb.Endpoint, @token_salt, %{user_id: user.id, role: user.roles})
  end

  @doc """
  Verifies the given token and returns the token claims if valid.

  Returns `{:ok, claims}` if valid, otherwise `{:error, reason}`.
  """
  @spec verify_token(binary()) :: {:error, :expired | :invalid | :missing} | {:ok, any()}
  def verify_token(token) do
    Token.verify(TimesinkWeb.Endpoint, @token_salt, token, max_age: @max_age)
  end

  @doc """
  Performs token authentication.

  This function delegates to `verify_token/1` and returns the token claims.
  """
  def token_auth(token) when is_binary(token) do
    with {:ok, claims} <- verify_token(token) do
      {:ok, claims}
    else
      _error -> {:error, :bad_credentials}
    end
  end
end
