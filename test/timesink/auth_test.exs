defmodule Timesink.AuthTest do
  use ExUnit.Case, async: true
  use Timesink.DataCase

  alias Timesink.Auth

  import Timesink.Factory

  test "generate_token/1 returns a binary token" do
    user = insert(:user)
    token = Auth.generate_token(user)
    assert is_binary(token)
  end

  test "verify_token/1 returns claims for a valid token" do
    user = insert(:user, roles: ["admin"])
    token = Auth.generate_token(user)
    assert {:ok, claims} = Auth.verify_token(token)
    assert (claims["user_id"] || claims[:user_id]) == user.id
    assert (claims["role"] || claims[:role]) == [:admin]
  end

  test "token_auth/1 returns error for an invalid token" do
    invalid_token = "invalid_token"
    assert {:error, :bad_credentials} = Auth.token_auth(invalid_token)
  end
end
