defmodule TimesinkWeb.Plugs.RequireAuthenticatedUser do
  @moduledoc """
  Used for routes that require the user to be authenticated.
  """
  import Plug.Conn
  import Phoenix.Controller
  import TimesinkWeb.Plugs.Helpers

  use TimesinkWeb, :verified_routes

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)

    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/sign-in")
      |> halt()
    end
  end
end
