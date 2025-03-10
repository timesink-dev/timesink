defmodule TimesinkWeb.Plugs.RedirectIfUserIsAuthenticated do
  @moduledoc """
  Used for routes that require the user to not be authenticated.
  """

  import Plug.Conn
  import Phoenix.Controller
  use TimesinkWeb, :verified_routes

  def init(default), do: default

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: ~p"/sign_in")
      |> halt()
    else
      conn
    end
  end
end
