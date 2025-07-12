defmodule TimesinkWeb.BlogLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, %{posts: posts}} =
      GhostContent.config(:timesink)
      |> GhostContent.get_posts()

    {:ok, assign(socket, :posts, posts)}
  end

  def render(assigns) do
    ~H"""
    <h1>Recent Blog Posts</h1>
    <ul>
      <%= for post <- @posts do %>
        <li><a href={~p"/blog/#{post.slug}"}>{post.title}</a></li>
      <% end %>
    </ul>
    """
  end
end
