# lib/timesink_web/controllers/blog_post_public_controller.ex
defmodule TimesinkWeb.BlogPostPublicController do
  use TimesinkWeb, :controller
  alias Timesink.BlogPost

  def comments(conn, %{"slug" => slug}) do
    with {:ok, %BlogPost{} = post} <- BlogPost.get_by(slug: slug) do
      post = Timesink.Repo.preload(post, :comments)

      render(conn, "comments_iframe.html", post: post)
    else
      _ -> send_resp(conn, 404, "Not found")
    end
  end
end
