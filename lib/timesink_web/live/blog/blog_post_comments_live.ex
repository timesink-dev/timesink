defmodule TimesinkWeb.BlogPostCommentsLive do
  use TimesinkWeb, :live_view
  alias Timesink.BlogPost
  alias Timesink.Comment

  def mount(%{"slug" => slug}, _session, socket) do
    current_user = socket.assigns.current_user || nil
    {:ok, post} = BlogPost.get_by(slug: slug)

    # Preload all comments (and their authors + parent references)
    post = Timesink.Repo.preload(post, comments: [:user])

    # Build nested comment tree from flat list
    nested_comments = build_comment_tree(post.comments)

    {:ok,
     socket
     |> assign(:post, %{post | comments: nested_comments})
     # if needed
     |> assign(:current_user, current_user)
     |> assign(:active_reply_id, nil), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h3 class="text-lg font-semibold text-mystery-white mb-4">Comments</h3>
      
    <!-- Join CTA -->
      <div class="mb-6 flex items-center justify-between border border-gray-700 rounded p-4 bg-gray-900">
        <div class="text-sm text-gray-300 font-medium">
          Join the conversation
        </div>
        <%= if @current_user do %>
          <!-- No buttons needed if signed in -->
        <% else %>
          <div class="flex gap-2">
            <.link
              target="_blank"
              rel="noopener noreferrer"
              href="https://38509a17a633.ngrok-free.app/sign_in"
              class="text-sm text-white bg-black px-3 py-1 rounded-md hover:bg-gray-800"
            >
              Sign in
            </.link>
            <.link
              href="https://38509a17a633.ngrok-free.app/join"
              class="text-sm text-white border border-gray-600 px-3 py-1 rounded-md hover:bg-gray-700"
            >
              Join
            </.link>
          </div>
        <% end %>
      </div>
      
    <!-- Comment input if signed in -->
      <%= if @current_user do %>
        <form phx-submit="submit_comment" class="mb-6 space-y-2" phx-target={@myself}>
          <textarea
            name="content"
            rows="3"
            placeholder="Add a comment…"
            class="w-full bg-gray-800 text-white text-sm p-3 rounded-md border border-gray-600 focus:border-white focus:outline-none resize-none"
          />
          <div class="flex justify-end">
            <button
              type="submit"
              class="text-sm text-white bg-mystery-black px-4 py-1.5 rounded-md hover:bg-gray-700"
            >
              Comment
            </button>
          </div>
        </form>
      <% end %>
      
    <!-- Comments list -->
      <.live_component
        module={TimesinkWeb.BlogPostCommentsList}
        id="comments"
        comments={@post.comments}
        current_user={@current_user}
        active_reply_id={@active_reply_id}
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

  def handle_event("set_reply_id", %{"id" => id}, socket) do
    {:noreply, assign(socket, :active_reply_id, String.to_integer(id))}
  end

  def handle_event("clear_reply_id", _params, socket) do
    {:noreply, assign(socket, :active_reply_id, nil)}
  end
end
