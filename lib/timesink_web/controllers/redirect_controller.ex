defmodule TimesinkWeb.RedirectController do
  use TimesinkWeb, :controller

  def redirect_to_showcases(conn, _params) do
    conn
    |> Phoenix.Controller.redirect(to: ~p"/admin/showcases")
    |> Plug.Conn.halt()
  end
end
