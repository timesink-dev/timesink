defmodule TimesinkWeb.OnlinePillLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.PubSubTopics
  alias TimesinkWeb.Presence

  @impl true
  def mount(_params, %{"user_id" => user_id, "username" => username}, socket) do
    topic = PubSubTopics.platform_presence_topic()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Timesink.PubSub, topic)

      Presence.track(
        self(),
        topic,
        to_string(user_id),
        %{username: username, joined_at: System.system_time(:second)}
      )
    end

    presence = Presence.list(topic)

    {:ok,
     socket
     |> assign(:topic, topic)
     |> assign(:presence, presence)
     |> assign(:open?, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Floating pill (site-wide) -->
    <div class="fixed bottom-4 right-4 z-40">
      <button
        phx-click="toggle"
        class="inline-flex items-center gap-2 rounded-lg border border-gray-800 bg-zinc-950/80 backdrop-blur px-6 py-2 text-sm text-gray-100 shadow-lg hover:bg-zinc-900/80"
        title="Show online members"
        aria-label="Show online members"
      >
        <!-- pulsing green dot -->
        <span class="relative inline-flex h-2.5 w-2.5">
          <span class="absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75 animate-ping">
          </span>
          <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-500"></span>
        </span>
        <span class="tabular-nums">{presence_count(@presence)} lobby</span>
      </button>
      
    <!-- Tiny popover list -->
      <%= if @open? do %>
        <div
          class="mt-2 w-64 rounded-xl border border-gray-800 bg-zinc-950/95 text-gray-100 shadow-xl overflow-hidden"
          role="dialog"
          aria-label="Online members"
        >
          <div class="px-3 py-2 text-xs uppercase tracking-wide text-gray-400 border-b border-gray-800">
            Online members
          </div>

          <div class="max-h-64 overflow-y-auto">
            <ul class="divide-y divide-gray-800 text-sm">
              <%= for name <- usernames(@presence) do %>
                <li class="px-3 py-2 flex items-center justify-between">
                  <span>{name}</span>
                  <span class="flex items-center gap-1 text-xs text-gray-400">
                    <span class="relative inline-flex h-2 w-2">
                      <span class="absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75 animate-ping">
                      </span>
                      <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                    </span>
                    online
                  </span>
                </li>
              <% end %>
            </ul>
          </div>

          <div class="px-3 py-2 border-t border-gray-800 text-right">
            <button phx-click="toggle" class="text-xs text-gray-300 hover:text-white">Close</button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :presence, Presence.list(socket.assigns.topic))}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    {:noreply, update(socket, :open?, &(!&1))}
  end

  defp presence_count(presence_map), do: map_size(presence_map)

  defp usernames(presence_map) do
    presence_map
    |> Enum.map(fn {_id, %{metas: metas}} ->
      case metas do
        [%{username: u} | _] -> u
        _ -> "Guest"
      end
    end)
    |> Enum.sort(:asc)
  end
end
