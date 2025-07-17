defmodule TimesinkWeb.BlogPostCommentsLive do
  use TimesinkWeb, :live_view
  alias Timesink.BlogPost
  alias Timesink.Comment
  alias Timesink.Repo

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, post} = BlogPost.get_by(slug: slug)

    # Preload all comments (and their authors + parent references)
    post = Timesink.Repo.preload(post, comments: [:user])

    # Build nested comment tree from flat list
    nested_comments = build_comment_tree(post.comments)

    {:ok,
     socket
     |> assign(:post, %{post | comments: nested_comments}), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-medium text-mystery-white my-8">Comments</h3>
      <.live_component
        module={TimesinkWeb.BlogPostCommentsList}
        id="comments"
        comments={@post.comments}
      />
    </div>
    """
  end

  defp build_comment_tree(comments) do
    by_parent =
      Enum.group_by(comments, fn
        %Comment{parent_id: nil} -> :root
        %Comment{parent_id: pid} -> pid
      end)

    # Recursively attach replies to each comment
    attach_replies(by_parent[:root] || [], by_parent)
  end

  defp attach_replies(comments, by_parent) do
    Enum.map(comments, fn comment ->
      children = Map.get(by_parent, comment.id, [])
      %{comment | replies: attach_replies(children, by_parent)}
    end)
  end
end
