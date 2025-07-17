defmodule TimesinkWeb.RedirectController do
  use TimesinkWeb, :controller

  def redirect_to_showcases(conn, _params) do
    conn
    |> Phoenix.Controller.redirect(to: ~p"/admin/showcases")
    |> Plug.Conn.halt()
  end

  def ghost_blog(conn, _params) do
    redirect(conn, external: "https://blog.timesinkpresents.com/")
  end

  def ghost_blog_post(conn, %{"slug" => slug}) do
    redirect(conn, external: "https://blog.timesinkpresents.com/#{slug}")
  end
end
