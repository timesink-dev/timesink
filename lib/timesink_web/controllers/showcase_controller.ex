defmodule TimesinkWeb.ShowcaseController do
  use TimesinkWeb, :controller

  def archives(conn, _params) do
    render(conn, :archives)
  end

  def upcoming(conn, _params) do
    render(conn, :upcoming)
  end
end
