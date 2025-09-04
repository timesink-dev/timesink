defmodule TimesinkWeb.BlogPostCommentsList do
  use Phoenix.LiveComponent

  attr :comments, :list, required: true
  attr :depth, :integer, default: 0
  attr :current_user, :map, default: nil
  attr :active_reply_id, :integer, default: nil

  def render(assigns) do
    ~H"""
    <div>
      dfdfs
    <!-- Comment List -->
      <ul class="space-y-4">
        <%= for comment <- @comments do %>
          <li class="flex items-start space-x-3">
            <!-- Avatar -->
            <div class="flex-shrink-0 w-8 h-8 rounded bg-gray-700 text-white flex items-center justify-center text-xs font-medium">
              {String.first(comment.user.first_name || "")}
            </div>
            
    <!-- Body -->
            <div class="flex-1">
              <!-- Header -->
              <div class="flex items-center gap-2 text-sm">
                <span class="font-medium text-white">{comment.user.first_name}</span>
                <span class="text-gray-500 text-xs">just now as</span>
              </div>
              
    <!-- Content -->
              <p class="mt-1 text-sm text-gray-300 leading-snug">
                {comment.content}
              </p>
              
    <!-- Reply Button -->
              <div class="mt-1 text-xs text-gray-400">
                <%= if @current_user do %>
                  <button
                    phx-click="set_reply_id"
                    phx-value-id={comment.id}
                    class="hover:underline text-gray-400"
                  >
                    Reply
                  </button>
                <% else %>
                  <a href="/sign_in" class="hover:underline text-gray-400">Reply</a>
                <% end %>
              </div>

              <%!-- <!-- Reply Input -->
              <%= if @current_user && @active_reply_id == comment.id do %>
                <form phx-submit="submit_reply" class="mt-2 space-y-2" phx-target={@myself}>
                  <input type="hidden" name="parent_id" value={comment.id} />
                  <textarea
                    name="content"
                    rows="3"
                    placeholder="Write a reply…"
                    class="w-full bg-gray-800 text-white text-sm p-2 rounded-md border border-gray-600 focus:border-white focus:outline-none resize-none"
                  />
                  <div class="flex justify-end">
                    <button
                      type="submit"
                      class="text-sm text-white bg-mystery-black px-3 py-1 rounded-md hover:bg-gray-700"
                    >
                      Reply as
                    </button>
                  </div>
                </form>
              <% end %> --%>
              
    <!-- Replies -->
              <%= if @depth == 0 && comment.replies && comment.replies != [] do %>
                <div class="mt-3 pl-6 border-l border-gray-700 space-y-3">
                  <%= for reply <- comment.replies do %>
                    <li class="flex items-start space-x-3">
                      <div class="w-8 h-8 rounded bg-gray-700 text-white flex items-center justify-center text-xs font-medium">
                        {String.first(reply.user.first_name || "")}
                      </div>
                      <div class="flex-1">
                        <div class="flex items-center gap-2 text-sm">
                          <span class="font-medium text-white">{reply.user.first_name}</span>
                          <span class="text-gray-500 text-xs">just now</span>
                        </div>
                        <p class="mt-1 text-sm text-gray-300 leading-snug">{reply.content}</p>
                      </div>
                    </li>
                  <% end %>
                </div>
              <% end %>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
