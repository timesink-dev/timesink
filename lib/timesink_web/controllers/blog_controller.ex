defmodule TimesinkWeb.BlogController do
  use TimesinkWeb, :controller

  def index(conn, _params) do
    # blogs = Blog.list_articles()
    render(conn, :index)
  end
end
