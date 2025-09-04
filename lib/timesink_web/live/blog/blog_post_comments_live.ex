defmodule TimesinkWeb.BlogPostCommentsLive do
  use TimesinkWeb, :live_view
  alias Timesink.{BlogPost, Comment, Accounts, Repo}

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    # Optional: accept a JWT/Signed token in query param for auth (see section 4)
    user = authenticate_from_token(params["t"])

    {:ok, post} = BlogPost.get_by(slug: slug)

    post =
      Repo.preload(post, comments: [:user])
      |> Map.update!(:comments, &one_level_tree/1)

    socket =
      socket
      |> assign(:post, post)
      # may be nil – that’s fine
      |> assign(:current_user, user)
      |> assign(:active_reply_id, nil)
      # stream for perf
      |> stream(:comments, post.comments)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="comments-root" phx-hook="IframeAutoHeight" class="max-w-2xl mx-auto">
      <h3 class="text-lg font-semibold text-mystery-white mb-4">Comments</h3>
      
    <!-- Join CTA -->
      <div class="mb-6 flex items-center justify-between border border-gray-700 rounded p-4 bg-gray-900">
        <div class="text-sm text-gray-300 font-medium">Join the discussion</div>
        <%= if @current_user do %>
          <span class="text-xs text-gray-500">Signed in</span>
        <% else %>
          <div class="flex gap-2">
            <button
              id="as"
              phx-hook="OpenIframePopup"
              data-url="/auth/iframe_start"
              class="text-sm text-white bg-black px-3 py-1 rounded-md hover:bg-gray-800"
            >
              Sign in as
            </button>
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
      
    <!-- New top-level comment -->
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
      
    <!-- Streamed list -->
      <ul id="comment-list" phx-update="stream" class="space-y-4">
        <%= for {dom_id, comment} <- @streams.comments do %>
          <li id={dom_id} class="flex items-start space-x-3">
            <!-- Avatar -->
            <div class="flex-shrink-0 w-8 h-8 rounded bg-gray-700 text-white flex items-center justify-center text-xs font-medium">
              {String.first(comment.user.first_name || "")}
            </div>
            
    <!-- Body -->
            <div class="flex-1">
              <div class="flex items-center gap-2 text-sm">
                <span class="font-medium text-white">{comment.user.first_name}</span>
                <span class="text-gray-500 text-xs">{relative_ts(comment.inserted_at)}</span>
              </div>

              <p class="mt-1 text-sm text-gray-300 leading-snug">{comment.content}</p>
              
    <!-- Reply CTA always visible -->
              <div class="mt-2 text-xs text-gray-400 flex gap-3">
                <%= if @current_user do %>
                  <button phx-click="set_reply_id" phx-value-id={comment.id} class="hover:underline">
                    Reply
                  </button>
                <% else %>
                  <a href="/sign_in" target="_blank" rel="noopener noreferrer" class="hover:underline">
                    Reply
                  </a>
                <% end %>
              </div>
              
    <!-- One-level replies (no recursion) -->
              <%= if comment.replies != [] do %>
                <div class="mt-3 pl-6 border-l border-gray-700 space-y-3">
                  <%= for reply <- comment.replies do %>
                    <div class="flex items-start space-x-3">
                      <div class="flex-shrink-0 w-7 h-7 rounded bg-gray-800 text-white flex items-center justify-center text-[10px] font-medium">
                        {String.first(reply.user.first_name || "")}
                      </div>
                      <div class="flex-1">
                        <div class="flex items-center gap-2 text-xs">
                          <span class="text-gray-200 font-medium">{reply.user.first_name}</span>
                          <span class="text-gray-500">{relative_ts(reply.inserted_at)}</span>
                        </div>
                        <p class="mt-0.5 text-sm text-gray-300 leading-snug">{reply.content}</p>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
              
    <!-- Reply box (inline) -->
              <%= if @current_user && @active_reply_id == comment.id do %>
                <form phx-submit="submit_reply" class="mt-3 space-y-2">
                  <input type="hidden" name="parent_id" value={comment.id} />
                  <textarea
                    name="content"
                    rows="3"
                    placeholder="Write a reply…"
                    class="w-full bg-gray-800 text-white text-sm p-2 rounded-md border border-gray-600 focus:border-white focus:outline-none resize-none"
                  />
                  <div class="flex justify-end gap-2">
                    <button
                      type="button"
                      phx-click="clear_reply_id"
                      class="text-sm text-gray-400 hover:text-gray-200"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="text-sm text-white bg-mystery-black px-3 py-1 rounded-md hover:bg-gray-700"
                    >
                      Reply
                    </button>
                  </div>
                </form>
              <% end %>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def handle_event("auth_token", %{"token" => token}, socket) do
    with {:ok, %{"uid" => uid} = claims} <-
           Phoenix.Token.verify(TimesinkWeb.Endpoint, "iframe:auth", token, max_age: 300),
         user <- Timesink.Accounts.User.get(uid) do
      {:noreply, assign(socket, current_user: user)}
    else
      # optionally flash error
      _ -> {:noreply, socket}
    end
  end

  # EVENTS (keep simple; IDs are UUID strings)
  @impl true
  def handle_event("set_reply_id", %{"id" => id}, socket),
    do: {:noreply, assign(socket, :active_reply_id, id)}

  @impl true
  def handle_event("clear_reply_id", _params, socket),
    do: {:noreply, assign(socket, :active_reply_id, nil)}

  @impl true
  def handle_event("submit_comment", %{"content" => content}, socket) do
    # TODO: insert comment; then push into stream:
    # {:ok, comment} = Comments.create_top_level(...)
    # {:noreply, stream_insert(socket, :comments, comment, at: 0)}
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_reply", %{"parent_id" => parent_id, "content" => content}, socket) do
    # TODO: insert reply; then refresh only that parent in stream (or refetch that parent’s replies)
    {:noreply, assign(socket, :active_reply_id, nil)}
  end

  # ---- helpers ----

  # Flatten -> one-level nested
  defp one_level_tree(comments) do
    by_parent = Enum.group_by(comments, & &1.parent_id)
    roots = Map.get(by_parent, nil, [])
    Enum.map(roots, fn c -> %{c | replies: Map.get(by_parent, c.id, [])} end)
  end

  # Optional token auth in iframe
  defp authenticate_from_token(nil), do: nil

  defp authenticate_from_token(token) do
    case Phoenix.Token.verify(TimesinkWeb.Endpoint, "iframe-auth", token, max_age: 60 * 60 * 6) do
      {:ok, user_id} -> Timesink.Accounts.User.get(user_id)
      _ -> nil
    end
  end

  defp relative_ts(nil), do: ""
  # keep it cheap
  defp relative_ts(dt), do: Calendar.strftime(dt, "%b %-d")
end
