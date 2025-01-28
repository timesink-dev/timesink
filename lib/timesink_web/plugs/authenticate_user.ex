defmodule TimesinkWeb.Plugs.AuthenticateUser do
  import Plug.Conn
  alias Phoenix.Token
  alias Timesink.Accounts.User
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> fetch_cookies(signed: ~w("auth_token current_user"))
    |> authenticate_user()
  end

  defp authenticate_user(conn) do
    # Try to get the token from the session or cookies
    token = get_session(conn, :auth_token)

    # Verify the token
    result = Token.verify(TimesinkWeb.Endpoint, "user_auth_salt", token)

    with {:ok, claims} <- result do
      # If verification succeeds, find the user
      user = User.get!(Map.get(claims, :user_id)) |> Timesink.Repo.preload(:profile)
      assign(conn, :current_user, user)
    else
      # If verification fails or any other error happens, redirect to sign-in
      _ ->
        conn
        |> put_flash(:error, "You must be signed in to access this page.")
        |> redirect(to: "/sign_in")
        |> halt()
    end
  end
end
