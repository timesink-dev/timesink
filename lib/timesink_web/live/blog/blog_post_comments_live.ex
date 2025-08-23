defmodule TimesinkWeb.BlogPostCommentsLive do
  use TimesinkWeb, :live_view
  alias Timesink.BlogPost
  alias Timesink.Comment

  def mount(%{"slug" => slug}, _session, socket) do
    current_user = Map.get(socket.assigns, :current_user, nil)
    IO.puts("this hre")
    {:ok, post} = BlogPost.get_by(slug: slug)

    post = Timesink.Repo.preload(post, comments: [:user])
    nested_comments = build_comment_tree(post.comments)

    {:ok,
     socket
     |> assign(:post, %{post | comments: nested_comments})
     |> assign(:current_user, current_user)
     |> assign(:active_reply_id, nil), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h3 class="text-lg font-semibold text-mystery-white mb-4">Comments</h3>
      
    <!-- Join CTA -->
      <div class="mb-6 flex items-center justify-between border border-gray-700 rounded p-4 bg-gray-900">
        <div class="text-sm text-gray-300 font-medium">Join the conversation</div>
        <%= if @current_user do %>
          <span class="text-xs text-gray-500">Signed in</span>
        <% else %>
          <div class="flex gap-2">
            <.link
              target="_blank"
              rel="noopener noreferrer"
              href="/sign_in"
              class="text-sm text-white bg-black px-3 py-1 rounded-md hover:bg-gray-800"
            >
              Sign in
            </.link>
            <.link
              target="_blank"
              rel="noopener noreferrer"
              href="/join"
              class="text-sm text-white border border-gray-600 px-3 py-1 rounded-md hover:bg-gray-700"
            >
              Join
            </.link>
          </div>
        <% end %>
      </div>
      
    <!-- New top-level comment box (no phx-target here!) -->
      <%= if @current_user do %>
        <form phx-submit="submit_comment" class="mb-6 space-y-2">
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

  def handle_event("set_reply_id", %{"id" => id}, socket) do
    # id is a UUID string; don't String.to_integer/1 it
    {:noreply, assign(socket, :active_reply_id, id)}
  end

  def handle_event("clear_reply_id", _params, socket) do
    {:noreply, assign(socket, :active_reply_id, nil)}
  end

  # build one-level nested tree
  defp build_comment_tree(comments) do
    by_parent =
      Enum.group_by(comments, fn
        %Comment{parent_id: nil} -> :root
        %Comment{parent_id: pid} -> pid
      end)

    attach_replies(by_parent[:root] || [], by_parent)
  end

  defp attach_replies(comments, by_parent) do
    Enum.map(comments, fn c ->
      children = Map.get(by_parent, c.id, [])
      # only one level deep
      %{c | replies: children}
    end)
  end
end
