defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias TimesinkWeb.Auth

  @spec sign_in(Plug.Conn, map()) ::
          {:error, :invalid_credentials} | Plug.Conn
  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}} = _params) do
    with {:ok, user} <-
           Auth.authenticate_user(%{email: email, password: password}) do
      conn
      |> Auth.log_in_user(user)
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/sign_in")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:info, "You have logged out succesfully.")
  end
end
