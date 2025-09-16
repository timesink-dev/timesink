defmodule TimesinkWeb.RedirectController do
  use TimesinkWeb, :controller

  def redirect_to_showcases(conn, _params) do
    conn
    |> Phoenix.Controller.redirect(to: ~p"/admin/showcases")
    |> Plug.Conn.halt()
  end

  def substack_blog(conn, _params) do
    redirect(conn, external: "https://timesinkpresents.substack.com/")
  end
end
