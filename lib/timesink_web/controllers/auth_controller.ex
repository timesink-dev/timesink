defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias Timesink.Auth

  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Auth.authenticate(%{"email" => email, "password" => password}) do
      {:ok, user, token} ->
        user = user |> Timesink.Repo.preload(:profile)

        conn
        |> put_session(:auth_token, token)
        |> put_session(:current_user, user)
        |> put_resp_cookie("auth_token", token, sign: true)
        |> put_resp_cookie("current_user", user, sign: true)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render("sign_in.html", email: email)
    end
  end

  def sign_out(conn, _params) do
    conn
    |> configure_session(drop: true)
    # Optional: Clear any auth cookies if you set them
    |> clear_auth_cookie()
    |> clear_current_user_cookie()
    |> put_flash(:info, "You have logged out succesfully.")
    # Redirect the user to the login page
    |> redirect(to: "/sign_in")
  end

  # Optional: Clear an auth cookie (if used)
  defp clear_auth_cookie(conn) do
    conn
    |> delete_resp_cookie("auth_token")
  end

  defp clear_current_user_cookie(conn) do
    conn
    |> delete_resp_cookie("current_user")
  end
end
