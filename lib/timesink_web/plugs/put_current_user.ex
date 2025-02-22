defmodule TimesinkWeb.Plugs.PutCurrentUser do
  import Plug.Conn
  import TimesinkWeb.Plugs.Helpers

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)
    assign(conn, :current_user, user)
  end
end
