defmodule TimesinkWeb.Plugs.PutCurrentUser do
  @moduledoc """
   Fetches the current user from the session and assigns it to the connection, i.e. `Plug.Conn`
  """
  import Plug.Conn
  import TimesinkWeb.Plugs.Helpers

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)
    assign(conn, :current_user, user)
  end
end
