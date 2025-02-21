defmodule TimesinkWeb.PageController do
  use TimesinkWeb, :controller
  import TimesinkWeb.Auth

  # plug :plug_check_logged_in when action in [:info]

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def info(conn, _params) do
    render(conn, :info, current_user: conn.assigns.current_user)
  end
end
