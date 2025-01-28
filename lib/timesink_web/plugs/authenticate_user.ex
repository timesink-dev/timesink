defmodule TimesinkWeb.Plugs.AuthenticateUser do
  import Plug.Conn
  alias Phoenix.Token
  alias Timesink.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(conn, label: "conn")

    case fetch_cookies(conn, :signed) do
      nil ->
        conn
        |> Plug.Conn.redirect_to(to: "/sign_in")
        |> halt()

      token ->
        case Token.verify(MyAppWeb.Endpoint, "user_auth", token, max_age: 7 * 24 * 60 * 60) do
          {:ok, claims} ->
            IO.inspect(token, label: "token verify")

            user = User.get!(claims["user_id"]) |> Timesink.Repo.preload(:profile)
            assign(conn, :current_user, user)

          {:error, _reason} ->
            conn
            # |> Plug.Conn.redirect_to(to: "/sign_in")
            |> halt()
        end
    end
  end

  # defp redirect_to_sigin(conn) do
  #   conn
  #   |> put_flash(:error, "You must be signed in to access this page.")
  #   |> redirect(to: "/sign_in")
  # end
end
