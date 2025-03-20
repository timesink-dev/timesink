defmodule TimesinkWeb.AuthTest do
  use ExUnit.Case, async: true
  use Timesink.DataCase

  alias Timesink.Accounts.User
  alias TimesinkWeb.Auth

  import Timesink.Factory
  import Plug.Conn
  import Phoenix.ConnTest

  describe "log_in_user/3" do
    test "sets session with token and redirects" do
      user = insert(:user)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> fetch_session()
        |> fetch_flash()

      conn = Auth.log_in_user(conn, user)

      session = get_session(conn)
      token = session["user_token"]

      assert token

      assert redirected_to(conn)
    end
  end

  describe "log_out_user/1" do
    test "clears session and deletes the user_token" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> fetch_session()
        |> fetch_flash()
        |> put_session(:user_token, "dummy_token")
        |> put_session(:live_socket_id, "dummy_live_socket")

      conn = Auth.log_out_user(conn)
      refute get_session(conn, :user_token)
      assert redirected_to(conn)
    end
  end

  describe "authenticate_user/1" do
    test "when the email is invalid - it returns an invalid credentials error" do
      password_hash = Argon2.hash_pwd_salt("password")
      insert(:user, password: password_hash)

      params = %{"email" => "test@example.com", "password" => "password"}
      assert {:error, :invalid_credentials} = Auth.authenticate_user(params)
    end

    test "when the password is invalid - it returns an invalid credentials error" do
      email = "test@example.com"
      params = %{"email" => email, "password" => "wrong_password"}
      insert(:user, email: email)

      assert {:error, :invalid_credentials} = Auth.authenticate_user(params)
    end

    test "when both the password and email are valid" do
      email = "test@example.com"
      password_hash = Argon2.hash_pwd_salt("correct_password")
      params = %{"email" => email, "password" => "correct_password"}
      insert(:user, email: email, password: password_hash)

      assert {:ok, %User{email: ^email}} = Auth.authenticate_user(params)
    end
  end
end
