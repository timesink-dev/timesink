defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film, Creative}
  alias TimesinkWeb.PubSubTopics
  alias Timesink.Repo

  require Logger

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      exhibition = Repo.preload(exhibition, [:showcase, :theater])

      film =
        Repo.preload(film, [
          {:video, [:blob]},
          {:poster, [:blob]},
          :genres,
          directors: [:creative],
          cast: [:creative],
          writers: [:creative],
          producers: [:creative],
          crew: [:creative]
        ])

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Timesink.PubSub, PubSubTopics.chat_topic(theater.id))
        Phoenix.PubSub.subscribe(Timesink.PubSub, PubSubTopics.scheduler_topic(theater.id))
        Phoenix.PubSub.subscribe(Timesink.PubSub, PubSubTopics.presence_topic(theater.id))

        TimesinkWeb.Presence.track(
          self(),
          PubSubTopics.presence_topic(theater.id),
          "#{socket.assigns.current_user.id}",
          %{
            username: socket.assigns.current_user.username,
            joined_at: System.system_time(:second)
          }
        )
      end

      presence_topic = PubSubTopics.presence_topic(theater.id)
      presence = TimesinkWeb.Presence.list(presence_topic)

      recent_msgs =
        Timesink.Comment.Exhibition.list_recent_exhibition_comments(exhibition.id)

      Logger.info(
        "Loaded #{length(recent_msgs)} existing comments for exhibition #{exhibition.id}. Comment IDs: #{Enum.map(recent_msgs, & &1.id) |> Enum.join(", ")}"
      )

      {:ok,
       socket
       # efficient diffs
       |> stream(:messages, recent_msgs)
       |> assign(:chat_input, "")
       |> assign(:typing_users, %{})
       |> assign(:theater, theater)
       |> assign(:exhibition, exhibition)
       |> assign(:film, film)
       |> assign(:user, socket.assigns.current_user)
       |> assign(:presence, presence)
       |> assign(:offset, nil)
       |> assign(:phase, nil)
       |> assign(:countdown, nil)
       |> assign(:pulse_seconds_only?, false)
       # UI state
       |> assign(:chat_open, false)
       |> assign(:active_panel_tab, :chat)
       |> assign(:has_messages?, length(recent_msgs) > 0)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div
      id="theater"
      phx-hook="TheaterBodyScroll"
      class="max-w-7xl md:max-w-4xl mx-auto px-4 md:px-6 mt-16 text-gray-100"
    >
      <!-- Header -->
      <div class="border-b border-white/10 pb-4 mb-10">
        <h1 class="text-lg font-bold font-gangster">{@theater.name}</h1>
        <p class="text-zinc-400 mt-2 text-sm">{@theater.description}</p>
      </div>
      
    <!-- Toolbar -->
      <div class="flex justify-between items-center mb-4">
        <div></div>
        <button
          phx-click="toggle_chat"
          class={[
            @chat_open && "invisible md:visible",
            "cursor-pointer text-sm px-4 py-2 rounded-lg border border-white/10 bg-white/[0.02] hover:bg-white/[0.06] text-gray-300 hover:text-white transition"
          ]}
          aria-haspopup="dialog"
          aria-expanded="false"
        >
          {if @chat_open, do: "Hide Chat", else: "Show Chat"}
        </button>
      </div>
      
    <!-- Main layout (mobile-first: stacked) -->
      <div class="flex flex-col md:flex-row md:gap-6 md:items-start">
        <!-- Left: Player + Film Info -->
        <div class="min-w-0 md:flex-1 transition-all duration-300">
          <% playback_id = Film.get_mux_playback_id(@film.video) %>
          <%= if @phase == :playing and playback_id do %>
            <div id="simulated-live-player" data-offset={@offset} phx-hook="SimulatedLivePlayback">
              <mux-player
                id={@film.title}
                playback-id={playback_id}
                metadata-video-title={@film.title}
                metadata-video-id={@film.id}
                metadata-viewer_user_id={@user.id}
                poster={Film.poster_url(@film.poster)}
                style="width: 100%; aspect-ratio: 16/9; border-radius: 10px; overflow: hidden; border: 1px solid #27272a;"
                stream-type="live"
                autoplay
                loop
                start-time={@offset}
              />
            </div>
            
    <!-- Film Info -->
            <div id="film-info" class="w-full mt-6 md:mt-8 border-t border-gray-800 pt-6 space-y-4">
              <div class="text-2xl font-semibold tracking-wide text-mystery-white">
                {@film.title}
                <span class="text-gray-400 text-base ml-2">({@film.year})</span>
              </div>

              <div class="text-xs md:text-sm text-mystery-white uppercase tracking-wider flex flex-wrap gap-x-3 md:gap-x-4 gap-y-2">
                <%= for genre <- @film.genres do %>
                  <span>{genre.name}</span>
                <% end %>
                <span>•</span>
                <span>{@film.duration} min</span>
                <span>•</span>
                <span>{String.upcase(to_string(@film.format))}</span>
                <span>•</span>
                <span>{@film.aspect_ratio} aspect</span>
                <%= if @film.color do %>
                  <span>•</span>
                  <span class="capitalize">{String.replace(to_string(@film.color), "_", " ")}</span>
                <% end %>
              </div>

              <div class="text-base text-gray-300 leading-relaxed font-light max-w-prose">
                {@film.synopsis}
              </div>

              <div class="text-sm text-gray-400 font-light space-y-2 pt-4 border-t border-gray-900 mt-6">
                <%= if Enum.any?(@film.directors) do %>
                  <div>
                    <span class="text-gray-500 uppercase tracking-wider">Director:</span>
                    <span class="text-gray-300">{join_names(@film.directors)}</span>
                  </div>
                <% end %>
                <%= if Enum.any?(@film.writers) do %>
                  <div>
                    <span class="text-gray-500 uppercase tracking-wider">Writer:</span>
                    <span class="text-gray-300">{join_names(@film.producers)}</span>
                  </div>
                <% end %>
                <%= if Enum.any?(@film.producers) do %>
                  <div>
                    <span class="text-gray-500 uppercase tracking-wider">Producer:</span>
                    <span class="text-gray-300">{join_names(@film.producers)}</span>
                  </div>
                <% end %>
                <%= if Enum.any?(@film.cast) do %>
                  <div>
                    <span class="text-gray-500 uppercase tracking-wider">Cast:</span>
                    <ul class="text-gray-300 list-disc list-inside">
                      {join_names_with_roles(@film.cast)}
                    </ul>
                  </div>
                <% end %>
                <%= if Enum.any?(@film.crew) do %>
                  <div>
                    <span class="text-gray-500 uppercase tracking-wider">Crew:</span>
                    <ul class="text-gray-300 list-disc list-inside">
                      {join_names_with_roles(@film.crew)}
                    </ul>
                  </div>
                <% end %>
              </div>

              <%!-- <div class="pt-6">
                <.button color="tertiary" class="hover:cursor-not-allowed" disabled>
                  More info
                </.button>
              </div> --%>
            </div>
          <% else %>
            <!-- Waiting/Countdown (unchanged) -->
            <div class="text-center text-gray-400 text-xl py-8">
              <%= if is_nil(@countdown) do %>
                <div class="flex flex-col items-center justify-center gap-2 text-gray-400">
                  <h3 class="font-semibold">Loading schedule...</h3>
                  <div class="h-4 w-4 border-2 border-t-transparent border-gray-400 rounded-full animate-spin" />
                </div>
              <% else %>
                <div class="flex flex-col justify-center text-center gap-y-2">
                  <h3 class="text-gray-400">
                    <%= case @phase do %>
                      <% :upcoming -> %>
                        This showcase is scheduled and will begin shortly.
                      <% :intermission -> %>
                        Intermission — next screening begins in
                      <% _ -> %>
                        Waiting for playback...
                    <% end %>
                  </h3>
                  <div class="flex justify-center gap-x-4 mt-2 text-center">
                    <%= for {label, value} <- breakdown_time(@countdown) do %>
                      <div class="flex flex-col items-center mx-2">
                        <span class={
                          "text-3xl font-bold" <>
                          (if label == :seconds and @pulse_seconds_only?, do: " pulse-second text-neon-red-lightest", else: "")
                        }>
                          {String.pad_leading(to_string(value), 2, "0")}
                        </span>
                        <span class="text-xs uppercase text-gray-400 tracking-wider">
                          {Atom.to_string(label)}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Right: Desktop side panel -->
        <aside class={
          [
            # <--- THIS FIXES IT
            "hidden md:block",
            "md:sticky md:top-20 md:self-start border border-white/10 rounded-2xl overflow-hidden bg-white/[0.02]",
            "md:transform-gpu transition-all duration-200",
            if(@chat_open,
              do: "opacity-100 md:w-96 md:translate-x-0",
              else: "opacity-0 md:w-0 md:translate-x-4 pointer-events-none"
            )
          ]
        }>
          <!-- Tabs -->
          <div class="flex items-center justify-between bg-white/[0.03] px-4 py-3 border-b border-white/10">
            <div class="flex gap-6 text-sm">
              <button
                phx-click="switch_tab"
                phx-value-to="chat"
                class={[
                  "pb-2 cursor-pointer",
                  @active_panel_tab == :chat && "text-white border-b-2 border-white",
                  @active_panel_tab != :chat && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Chat
              </button>
              <button
                phx-click="switch_tab"
                phx-value-to="online"
                class={[
                  "pb-2 cursor-pointer",
                  @active_panel_tab == :online && "text-white border-b-2 border-white",
                  @active_panel_tab != :online && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Live Audience
              </button>
            </div>
          </div>
          <div id="chat-panel-desktop" class="bg-white/[0.01] relative">
            <!-- This is where the jump button will be absolutely positioned -->

            <div class={@active_panel_tab == :chat || "hidden"}>
              <!-- Scrollable chat body (fixed height) -->
              <div id="chat-body-desktop" class="max-h-[40vh] overflow-y-auto relative">
                <%= if not @has_messages? do %>
                  <!-- Empty state placeholder -->
                  <div class="flex items-center justify-center h-full min-h-[200px] px-4 py-8">
                    <div class="text-center">
                      <div class="text-zinc-400 text-sm mb-2">No messages yet</div>
                      <div class="text-zinc-500 text-xs">Be the first to start the conversation!</div>
                    </div>
                  </div>
                <% else %>
                  <!-- STREAMED LIST (desktop only) -->
                  <ul
                    id="chat-list"
                    phx-update="stream"
                    phx-hook="ChatAutoScroll"
                    data-scroll="#chat-body-desktop"
                    data-host="#chat-panel-desktop"
                    class="divide-y divide-white/5"
                  >
                    <%= for {dom_id, msg} <- @streams.messages do %>
                      <li id={dom_id} class="px-4 py-3">
                        <div class="flex items-center justify-between">
                          <span class="font-medium text-zinc-300 text-sm">
                            {(msg.user && "@" <> msg.user.username) || "Member"}
                          </span>
                          <span class="text-xs text-zinc-400">{chat_time(msg.inserted_at)}</span>
                        </div>
                        <p class="text-gray-100 text-sm mt-1">{msg.content}</p>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
                
    <!-- TYPING -->
                <%= if map_size(@typing_users) > 0 do %>
                  <div class="px-4 py-2 text-xs text-zinc-400 border-t border-white/5">
                    {typing_line(@typing_users, @presence)}
                  </div>
                <% end %>
              </div>
              
    <!-- INPUT (outside scroll area) -->
              <form phx-submit="chat:send" class="p-3 border-t border-white/10">
                <div class="flex items-center gap-2">
                  <input
                    type="text"
                    name="chat[body]"
                    value={@chat_input}
                    placeholder="Type a message…"
                    phx-change="chat:typing"
                    phx-debounce="100"
                    class="w-full bg-white/[0.04] border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20"
                    autocomplete="off"
                  />
                  <button class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-white/[0.06] text-gray-200 hover:bg-white/[0.10] transition">
                    Send
                  </button>
                </div>
              </form>
            </div>
            
    <!-- Live Audience Tab Content -->
            <div class={[
              "max-h-[65vh] overflow-y-auto p-3",
              @active_panel_tab == :online || "hidden"
            ]}>
              <%= if map_size(@presence) > 0 do %>
                <ul class="space-y-2">
                  <%= for {_user_id, %{metas: [meta | _]}} <- @presence do %>
                    <li class="flex items-center justify-between rounded-lg border border-white/10 px-3 py-2 bg-white/[0.02] hover:bg-white/[0.04] transition">
                      <div class="flex items-center gap-3">
                        <div class="h-7 w-7 rounded-full bg-white/[0.08] text-gray-100 flex items-center justify-center text-[11px] font-semibold">
                          {meta.username |> String.first() |> String.upcase()}
                        </div>
                        <span class="text-sm text-gray-100">{meta.username}</span>
                      </div>
                      <span class="flex items-center gap-1 text-xs text-zinc-400">
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
              <% else %>
                <div class="text-center text-zinc-400 text-sm py-8">
                  No one is currently watching
                </div>
              <% end %>
            </div>
          </div>
        </aside>
      </div>
      
    <!-- Mobile chat drawer -->
      <div class={[
        "md:hidden fixed inset-0 z-50 flex items-end transition-opacity duration-200",
        if(@chat_open, do: "opacity-100 pointer-events-auto", else: "opacity-0 pointer-events-none")
      ]}>
        <!-- backdrop -->
        <div class="absolute inset-0 bg-black/70" phx-click="toggle_chat" aria-hidden="true"></div>
        
    <!-- sheet -->
        <div class={[
          "relative w-full rounded-t-2xl border-t border-white/10 bg-backroom-black transition-transform duration-300 ease-out",
          if(@chat_open, do: "translate-y-0", else: "translate-y-full")
        ]}>
          <div class="flex items-center justify-between px-4 py-3 border-b border-white/10">
            <div class="flex gap-4 text-sm">
              <button
                phx-click="switch_tab"
                phx-value-to="chat"
                class={[
                  "pb-2 cursor-pointer",
                  @active_panel_tab == :chat && "text-white border-b-2 border-white",
                  @active_panel_tab != :chat && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Chat
              </button>
              <button
                phx-click="switch_tab"
                phx-value-to="online"
                class={[
                  "pb-2 cursor-pointer",
                  @active_panel_tab == :online && "text-white border-b-2 border-white",
                  @active_panel_tab != :online && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Live Audience
              </button>
            </div>
            <button class="text-gray-300" phx-click="toggle_chat" aria-label="Close">✕</button>
          </div>

          <div id="mobile-chat-panel" class="h-[50vh] flex flex-col relative">
            <div id="mobile-chat-body" class="flex-1 overflow-y-auto overscroll-contain">
              <div class={@active_panel_tab == :chat || "hidden"}>
                <%= if not @has_messages? do %>
                  <!-- Empty state placeholder -->
                  <div class="flex items-center justify-center h-full min-h-[300px] px-4 py-8">
                    <div class="text-center">
                      <div class="text-zinc-400 text-sm mb-2">No messages yet</div>
                      <div class="text-zinc-500 text-xs">Be the first to start the conversation!</div>
                    </div>
                  </div>
                <% else %>
                  <!-- Mobile chat list with streaming -->
                  <ul
                    id="mobile-chat-list"
                    phx-update="stream"
                    phx-hook="ChatAutoScroll"
                    data-scroll="#mobile-chat-body"
                    data-host="#mobile-chat-panel"
                    class="divide-y divide-white/5 text-sm"
                  >
                    <%= for {dom_id, msg} <- @streams.messages do %>
                      <li id={"m-#{dom_id}"} class="px-4 py-3">
                        <div class="flex items-center justify-between">
                          <span class="font-medium text-zinc-300">
                            {(msg.user && msg.user.username) || "Member"}
                          </span>
                          <span class="text-xs text-zinc-400">{chat_time(msg.inserted_at)}</span>
                        </div>
                        <p class="text-gray-100 text-sm mt-1">{msg.content}</p>
                      </li>
                    <% end %>
                  </ul>

                  <%= if map_size(@typing_users) > 0 do %>
                    <div class="px-4 py-2 text-xs text-zinc-400 border-t border-white/5">
                      {typing_line(@typing_users, @presence)}
                    </div>
                  <% end %>
                <% end %>
              </div>
              
    <!-- Mobile Live Audience Tab Content -->
              <div class={[
                "p-3",
                @active_panel_tab == :online || "hidden"
              ]}>
                <%= if map_size(@presence) > 0 do %>
                  <ul class="space-y-2">
                    <%= for {_user_id, %{metas: [meta | _]}} <- @presence do %>
                      <li class="flex items-center justify-between rounded-lg border border-white/10 px-3 py-2 bg-white/[0.02]">
                        <div class="flex items-center gap-3">
                          <div class="h-7 w-7 rounded-full bg-white/[0.08] text-gray-100 flex items-center justify-center text-[11px] font-semibold">
                            {meta.username |> String.first() |> String.upcase()}
                          </div>
                          <span class="text-sm text-gray-100">{meta.username}</span>
                        </div>
                        <span class="flex items-center gap-1 text-xs text-zinc-400">
                          <span class="relative inline-flex h-2 w-2">
                            <span class="absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75 animate-ping">
                            </span>
                            <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500">
                            </span>
                          </span>
                          online
                        </span>
                      </li>
                    <% end %>
                  </ul>
                <% else %>
                  <div class="text-center text-zinc-400 text-sm py-8">
                    No one is currently watching
                  </div>
                <% end %>
              </div>
            </div>

            <%= if @active_panel_tab == :chat do %>
              <form phx-submit="chat:send" class="p-3 border-t border-white/10 bg-backroom-black">
                <div class="flex items-center gap-2">
                  <input
                    type="text"
                    name="chat[body]"
                    value={@chat_input}
                    placeholder="Type a message…"
                    phx-change="chat:typing"
                    phx-debounce="100"
                    class="w-full bg-white/[0.04] border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20"
                    autocomplete="off"
                  />
                  <button class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-white/[0.06] text-gray-200 hover:bg-white/[0.10] transition">
                    Send
                  </button>
                </div>
              </form>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────
  # Tick / Presence / Phase (unchanged)
  # ───────────────────────────────────────────────────────────
  def handle_info(
        %{event: "tick", playback_state: %{phase: phase, offset: offset, countdown: countdown}},
        socket
      ) do
    time_parts = breakdown_time(countdown || 0)
    pulse_seconds_only? = Enum.all?(time_parts, fn {unit, _} -> unit == :seconds end)

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:countdown, countdown)
     |> assign(:pulse_seconds_only?, pulse_seconds_only?)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = TimesinkWeb.Presence.list(topic)
    {:noreply, assign(socket, presence: presence)}
  end

  def handle_info(
        %{
          event: "phase_change",
          playback_state: %{phase: phase, offset: offset, countdown: countdown}
        },
        socket
      ) do
    {:noreply,
     socket |> assign(:phase, phase) |> assign(:offset, offset) |> assign(:countdown, countdown)}
  end

  def handle_info({:new_message, msg}, socket) do
    {:noreply,
     socket
     |> stream_insert(:messages, msg)
     |> assign(:has_messages?, true)}
  end

  def handle_info({:typing, %{user_id: uid}}, socket) do
    # reset a 2s timer per user
    if ref = socket.assigns.typing_users[uid], do: Process.cancel_timer(ref)
    ref = Process.send_after(self(), {:typing_clear, uid}, 2000)
    {:noreply, assign(socket, :typing_users, Map.put(socket.assigns.typing_users, uid, ref))}
  end

  def handle_info({:typing_clear, uid}, socket) do
    {:noreply, assign(socket, :typing_users, Map.delete(socket.assigns.typing_users, uid))}
  end

  # ───────────────────────────────────────────────────────────
  # Events
  # ───────────────────────────────────────────────────────────
  def handle_event("toggle_chat", _params, socket) do
    new_state = not socket.assigns.chat_open

    {:noreply,
     socket
     |> assign(:chat_open, new_state)
     |> push_event("toggle_body_scroll", %{prevent: new_state})}
  end

  def handle_event("switch_tab", %{"to" => to}, socket) do
    tab = if to == "online", do: :online, else: :chat
    {:noreply, assign(socket, :active_panel_tab, tab)}
  end

  # debounced on input change
  def handle_event("chat:typing", _params, socket) do
    if user = socket.assigns.user do
      Phoenix.PubSub.broadcast_from(
        Timesink.PubSub,
        self(),
        PubSubTopics.chat_topic(socket.assigns.theater.id),
        {:typing, %{user_id: user.id, username: user.username}}
      )
    end

    {:noreply, socket}
  end

  # submit new message
  def handle_event("chat:send", %{"chat" => %{"body" => body}}, socket) do
    user = socket.assigns.user
    theater_id = socket.assigns.theater.id
    exhibition_id = socket.assigns.exhibition.id
    body = (body || "") |> String.trim()

    cond do
      # or flash: sign in to chat
      is_nil(user) ->
        {:noreply, socket}

      body == "" ->
        {:noreply, socket}

      true ->
        msg =
          Timesink.Comment.Exhibition.create_exhibition_comment!(%{
            content: body,
            assoc_id: exhibition_id,
            user_id: user.id
          })

        Logger.info(
          "Created comment: id=#{msg.id}, content=#{msg.content}, user_id=#{msg.user_id}, assoc_id=#{msg.assoc_id}"
        )

        Phoenix.PubSub.broadcast(
          Timesink.PubSub,
          PubSubTopics.chat_topic(theater_id),
          {:new_message, msg}
        )

        {:noreply,
         socket
         |> assign(:chat_input, "")
         |> stream_insert(:messages, msg)
         |> assign(:has_messages?, true)}
    end
  end

  # ───────────────────────────────────────────────────────────
  # Helpers (unchanged)
  # ───────────────────────────────────────────────────────────
  defp breakdown_time(nil), do: []
  defp breakdown_time(seconds) when is_float(seconds), do: breakdown_time(trunc(seconds))

  defp breakdown_time(total) when is_integer(total) do
    days = div(total, 86_400)
    hours = rem(total, 86_400) |> div(3_600)
    minutes = rem(total, 3_600) |> div(60)
    seconds = rem(total, 60)

    all_parts = [{:days, days}, {:hours, hours}, {:minutes, minutes}, {:seconds, seconds}]

    # Filter out zero values, but keep seconds if minutes are shown (for proper time format)
    filtered = Enum.filter(all_parts, fn {_k, v} -> v > 0 end)

    # If we have minutes but no seconds in the filtered list, add seconds back
    has_minutes? = Enum.any?(filtered, fn {k, _} -> k == :minutes end)
    has_seconds? = Enum.any?(filtered, fn {k, _} -> k == :seconds end)

    if has_minutes? and not has_seconds? do
      filtered ++ [{:seconds, 0}]
    else
      filtered
    end
  end

  defp join_names([]), do: ""

  defp join_names(creatives),
    do: creatives |> Enum.map(fn %{creative: c} -> Creative.full_name(c) end) |> Enum.join(", ")

  defp join_names_with_roles([]), do: ""

  defp join_names_with_roles(creatives) do
    creatives
    |> Enum.map(fn %{creative: c, subrole: r} ->
      case r do
        nil -> Creative.full_name(c)
        "" -> Creative.full_name(c)
        _ -> "#{Creative.full_name(c)} (#{r})"
      end
    end)
    |> Enum.join(", ")
  end

  defp chat_time(%NaiveDateTime{} = ndt), do: chat_time(DateTime.from_naive!(ndt, "Etc/UTC"))

  defp chat_time(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, dt, :second)

    cond do
      # Less than 60 seconds ago
      diff_seconds < 60 ->
        "just now"

      # Less than 60 minutes ago
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"

      # Less than 24 hours ago
      diff_seconds < 86_400 ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"

      # Less than 7 days ago - show day name
      diff_seconds < 604_800 ->
        Calendar.strftime(dt, "%a %-I:%M %p")

      # Older - show date
      true ->
        Calendar.strftime(dt, "%b %-d")
    end
  end

  # Build "Alice is typing…" using presence usernames
  defp typing_line(typing_users, presence) do
    typing_ids = Map.keys(typing_users) |> MapSet.new(fn id -> to_string(id) end)

    names =
      presence
      |> Enum.filter(fn {id, _} -> MapSet.member?(typing_ids, id) end)
      |> Enum.map(fn {_id, %{metas: [%{username: u} | _]}} -> u end)

    case names do
      [] -> ""
      [a] -> "#{a} is typing…"
      [a, b] -> "#{a} and #{b} are typing…"
      _many -> "Several people are typing…"
    end
  end
end
