defmodule TimesinkWeb.BlogPostCommentsList do
  use Phoenix.LiveComponent

  attr :comments, :list, required: true
  attr :depth, :integer, default: 0

  def render(assigns) do
    ~H"""
    <ul class="space-y-4">
      <%= for comment <- @comments do %>
        {# remove flex here for 1-levl nesting appearnce #}
        <li class="group grid grid-cols-[32px_1fr] gap-3 items-start">
          <!-- Avatar -->
          <div class="flex-shrink-0 w-8 h-8 rounded-md bg-gray-800 text-xs text-mystery-white flex items-center justify-center font-medium">
            {String.first(comment.user.first_name)}
          </div>
          
    <!-- Content -->
          <div class="flex-1">
            <!-- Name + Timestamp -->
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-mystery-white leading-tight">
                {comment.user.first_name}
              </span>
              <span class="text-xs text-gray-500 leading-tight">just now</span>
            </div>
            
    <!-- Message -->
            <p class="mt-1 text-sm text-gray-300 leading-snug">
              {comment.content}
            </p>
            
    <!-- Action -->
            <div class="mt-1 text-xs text-gray-500 opacity-0 group-hover:opacity-100 transition">
              <button class="hover:text-gray-300 hover:underline">Reply</button>
            </div>
            <%= if comment.replies && comment.replies != [] do %>
              <.live_component
                module={__MODULE__}
                id={"comment-thread-#{comment.id}"}
                comments={comment.replies}
                depth={@depth + 1}
              />
            <% end %>
          </div>
        </li>
      <% end %>
    </ul>
    """
  end
end
