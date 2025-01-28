defmodule TimesinkWeb.Plugs.AuthenticateAdmin do
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
    token = get_session(conn, :auth_token)

    result = Token.verify(TimesinkWeb.Endpoint, "user_auth_salt", token)

    case result do
      {:ok, claims} ->
        user = User.get!(Map.get(claims, :user_id)) |> Timesink.Repo.preload(:profile)

        # Check if user has the :admin role
        if :admin in Map.get(user, :roles, []) do
          # Assign the user and return the updated conn
          assign(conn, :current_user, user)
        else
          # If not an admin, return a forbidden response
          conn
          |> redirect_to_forbidden()
          |> halt()  # This halts further plug processing
        end

      {:error, _reason} ->
        # If the token verification fails, return to the login page
        conn
        |> redirect_to_login()
        |> halt()  # This halts further plug processing
    end
  end

  defp redirect_to_login(conn) do
    conn
    |> put_flash(:error, "You must be logged in to access this page.")
    |> redirect(to: "/sign_in")
  end

  defp redirect_to_forbidden(conn) do
    conn
    |> put_flash(:error, "You do not have permission to access this page.")
    |> redirect(to: "/sign_in")
  end
end
