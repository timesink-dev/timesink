defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias Timesink.Accounts.User
  alias Timesink.Auth

  @spec sign_in(Plug.Conn, map()) ::
          {:error, :invalid_credentials} | {:ok, nil | [map()] | %{optional(atom()) => any()}}
  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}}) do
    with {:ok, user} <-
           User.authenticate(%{email: email, password: password}) do
      conn
      |> Auth.log_in_user(user)

      {:ok, user}
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
