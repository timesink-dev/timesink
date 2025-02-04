defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias Timesink.Accounts.User
  alias Timesink.Accounts.Auth

  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case User.authenticate(%{"email" => email, "password" => password}) do
      {:ok, user} ->
        user = user |> Timesink.Repo.preload(:profile)

        conn
        |> Auth.log_in_user(user)

      :error ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render("sign_in.html", email: email)
    end
  end

  def sign_out(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:info, "You have logged out succesfully.")
  end
end
