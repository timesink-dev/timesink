defmodule TimesinkWeb.AuthControllerTest do
  use TimesinkWeb.ConnCase, async: true
  import Timesink.Factory
  import Phoenix.ConnTest

  describe "sign in" do
    test "successful sign in sets session with token, flash, and redirects", %{conn: conn} do
      insert(:user, email: "test@example.com")

      params = %{
        "user" => %{
          "email" => "test@example.com",
          "password" => "password"
        }
      }

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_session()
        |> post("/sign-in", params)

      assert redirected_to(conn) == "/now-playing"
      assert is_binary(get_session(conn, "user_token"))

      # Follow the redirect to read the flash reliably
      conn = follow_redirect(conn, 302)

      assert get_flash(conn, :info) =~ "Welcome back!"
    end

    test "failed sign in sets flash error and redirects back to sign in", %{conn: conn} do
      params = %{
        "user" => %{
          "email" => "nonexistent@example.com",
          "password" => "wrong_password"
        }
      }

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_session()
        |> post("/sign-in", params)

      assert redirected_to(conn) == "/sign-in"

      conn = follow_redirect(conn, 302)

      assert get_flash(conn, :error) =~ "Invalid credentials"
    end
  end

  describe "sign out" do
    test "sign out clears session and redirects", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"user_token" => "dummy_token", "live_socket_id" => "dummy_live"})
        |> fetch_session()
        |> post("/sign_out", %{})

      assert redirected_to(conn) == "/"
      refute get_session(conn, "user_token")

      conn = follow_redirect(conn, 302)

      assert get_flash(conn, :info) =~ "You have logged out succesfully"
    end
  end
end
