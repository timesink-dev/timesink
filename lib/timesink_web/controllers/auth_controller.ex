defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias TimesinkWeb.Auth

  @spec sign_in(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}} = _params) do
    with {:ok, user} <-
           Auth.authenticate_user(%{email: email, password: password}) do
      conn
      |> Auth.log_in_user(user)
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/sign-in")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:info, "You have logged out succesfully.")
  end

  @spec complete_onboarding(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def complete_onboarding(conn, %{"token" => token}) do
    conn
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> put_flash(:info, "Welcome to Timesink!")
    |> redirect(to: "/now-playing?welcome=1")
  end
end
