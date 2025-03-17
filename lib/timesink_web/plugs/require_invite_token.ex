defmodule TimesinkWeb.Plugs.RequireInviteToken do
  import Plug.Conn
  import Phoenix.Controller
  use TimesinkWeb, :verified_routes

  def init(_opts), do: nil

  def call(conn, _opts) do
    if get_session(conn, :invite_token) do
      conn
    else
      conn
      |> put_flash(:error, "You must have a valid invite to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
