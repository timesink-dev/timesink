defmodule TimesinkWeb.PageController do
  use TimesinkWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def info(conn, _params) do
    render(conn, :info, current_user: conn.assigns.current_user)
  end

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render("404.html")
  end
end
