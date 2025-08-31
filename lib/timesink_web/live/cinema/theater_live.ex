defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film, Creative}
  alias TimesinkWeb.PubSubTopics
  alias Timesink.Repo

  require Logger

  # ───────────────────────────────────────────────────────────
  # Mount
  # ───────────────────────────────────────────────────────────
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

      recent_msgs = Timesink.Comment.Theater.list_recent_theater_comments(theater.id, 100)

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
       |> assign(:chat_open, true)
       |> assign(:active_panel_tab, :chat)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  # ───────────────────────────────────────────────────────────
  # Events
  # ───────────────────────────────────────────────────────────
  def handle_event("toggle_chat", _params, socket) do
    {:noreply, update(socket, :chat_open, fn v -> not v end)}
  end

  def handle_event("switch_tab", %{"to" => to}, socket) do
    tab = if to == "online", do: :online, else: :chat
    {:noreply, assign(socket, :active_panel_tab, tab)}
  end

  # ───────────────────────────────────────────────────────────
  # Render
  # ───────────────────────────────────────────────────────────
  def render(assigns) do
    ~H"""
    <div id="theater" class="max-w-7xl mx-auto px-4 md:px-6 mt-10 text-gray-100">
      <!-- Header -->
      <div class="border-b border-gray-800 pb-5 mb-6 md:mb-8">
        <h1 class="text-2xl md:text-3xl font-bold font-brand">{@theater.name}</h1>
        <p class="text-gray-400 mt-2 text-sm md:text-base">{@theater.description}</p>
      </div>
      
    <!-- Toolbar -->
      <div class="flex justify-between items-center mb-4">
        <div></div>
        <button
          phx-click="toggle_chat"
          class={[
            @chat_open && "invisible md:visible",
            "bg-dark-theater-primary text-sm text-gray-300 hover:text-white px-3 py-1 rounded bg-zinc-900/60 border border-gray-700"
          ]}
          aria-haspopup="dialog"
          aria-expanded="false"
        >
          {if @chat_open, do: "Hide Chat", else: "Show Chat"}
        </button>
      </div>
      
    <!-- Main layout (mobile-first: stacked) -->
      <div class="flex flex-col md:flex-row md:gap-6">
        <!-- Left: Player + Film Info -->
        <div class={[
          "min-w-0 md:flex-1 transition-all",
          not @chat_open && "md:max-w-5xl md:mx-auto"
        ]}>
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

              <div class="pt-6">
                <.button color="tertiary" class="hover:cursor-not-allowed" disabled>
                  More info
                </.button>
              </div>
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
        
    <!-- Right: Desktop side panel (reverted to earlier height/feel) -->
        <%= if @chat_open do %>
          <aside class="hidden md:block md:w-96 md:sticky md:top-20 md:self-start border border-gray-800 rounded-xl overflow-hidden bg-zinc-950/60">
            <!-- Tabs -->
            <div class="flex items-center justify-between bg-zinc-900/70 px-4 py-3 border-b border-gray-800">
              <div class="flex gap-6 text-sm">
                <button
                  phx-click="switch_tab"
                  phx-value-to="chat"
                  class={[
                    "pb-2",
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
                    "pb-2",
                    @active_panel_tab == :online && "text-white border-b-2 border-white",
                    @active_panel_tab != :online && "text-gray-400 hover:text-gray-200"
                  ]}
                >
                  Live Audience
                </button>
              </div>
            </div>
            
    <!-- Body (scroll-limited like before) -->
            <div class="bg-zinc-950/60">
              <%= if @active_panel_tab == :chat do %>
                <!-- CHAT LIST -->
                <ul
                  id="chat-list"
                  phx-update="stream"
                  phx-hook="ChatAutoScroll"
                  class="divide-y divide-gray-800"
                >
                  <%= for {dom_id, msg} <- @streams.messages do %>
                    <li id={dom_id} class="px-4 py-3">
                      <div class="flex items-center justify-between">
                        <span class="font-medium text-gray-100">
                          {(msg.user && msg.user.username) || "Member"}
                        </span>
                        <span class="text-xs text-gray-400">{chat_time(msg.inserted_at)}</span>
                      </div>
                      <p class="text-gray-200 text-sm mt-1">{msg.content}</p>
                    </li>
                  <% end %>
                </ul>
                
    <!-- TYPING -->
                <%= if map_size(@typing_users) > 0 do %>
                  <div class="px-4 py-2 text-xs text-gray-400 border-t border-gray-800">
                    {typing_line(@typing_users, @presence)}
                  </div>
                <% end %>
                
    <!-- INPUT -->
                <form phx-submit="chat:send" class="p-3 border-t border-gray-800">
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      name="chat[body]"
                      value={@chat_input}
                      placeholder="Type a message…"
                      phx-change="chat:typing"
                      phx-debounce="500"
                      class="w-full bg-zinc-900/70 border border-gray-800 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-600"
                      autocomplete="off"
                    />
                    <button class="inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-zinc-800 text-gray-200 hover:bg-zinc-700">
                      Send
                    </button>
                  </div>
                </form>
              <% else %>
                <div class="max-h-[60vh] overflow-y-auto p-3">
                  <ul class="space-y-2">
                    <%= for name <- ["Jane", "David", "Emily", "Marco", "Anya", "You"] do %>
                      <li class="flex items-center justify-between rounded-lg border border-gray-800 px-3 py-2">
                        <div class="flex items-center gap-3">
                          <div class="h-7 w-7 rounded-full bg-zinc-700 text-gray-100 flex items-center justify-center text-[11px] font-semibold">
                            {String.first(name) |> String.upcase()}
                          </div>
                          <span class="text-sm text-gray-100">{name}</span>
                        </div>
                        <span class="flex items-center gap-1 text-xs text-gray-400">
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
                </div>
              <% end %>
            </div>
          </aside>
        <% end %>
      </div>
      
    <!-- Mobile chat drawer (unchanged, still great) -->
      <%= if @chat_open do %>
        <div class="md:hidden fixed inset-0 z-50">
          <!-- backdrop -->
          <div class="absolute inset-0 bg-black/60" phx-click="toggle_chat" aria-hidden="true"></div>
          
    <!-- sheet -->
          <div class="absolute inset-x-0 bottom-0 rounded-t-2xl border-t border-gray-800 bg-zinc-950/95">
            <div class="flex items-center justify-between px-4 py-3 border-b border-gray-800">
              <div class="flex gap-4 text-sm">
                <button
                  phx-click="switch_tab"
                  phx-value-to="chat"
                  class={[
                    "pb-2",
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
                    "pb-2",
                    @active_panel_tab == :online && "text-white border-b-2 border-white",
                    @active_panel_tab != :online && "text-gray-400 hover:text-gray-200"
                  ]}
                >
                  Live Audience
                </button>
              </div>
              <button class="text-gray-300" phx-click="toggle_chat" aria-label="Close">✕</button>
            </div>

            <div class="h-[70vh] flex flex-col">
              <div class="flex-1 overflow-y-auto">
                <%= if @active_panel_tab == :chat do %>
                  <ul class="divide-y divide-gray-800 text-sm">
                    <li class="px-4 py-3">
                      <div class="flex items-center justify-between">
                        <span class="font-medium text-gray-100">Jane</span>
                        <span class="text-xs text-gray-400">1:20 · 13h</span>
                      </div>
                      <p class="text-gray-200 text-sm mt-1">Hello! How’s everyone doing?</p>
                    </li>
                    <li class="px-4 py-3">
                      <div class="flex items-center justify-between">
                        <span class="font-medium text-gray-100">David</span>
                        <span class="text-xs text-gray-400">1:21 · 13h</span>
                      </div>
                      <p class="text-gray-200 text-sm mt-1">Hi there!</p>
                    </li>
                    <li class="px-4 py-3">
                      <div class="flex items-center justify-between">
                        <span class="font-medium text-gray-100">Emily</span>
                        <span class="text-xs text-gray-400">1:34 · 14h</span>
                      </div>
                      <p class="text-gray-200 text-sm mt-1">
                        Great to be here!<br />Yes, this is awesome
                      </p>
                    </li>
                  </ul>
                <% else %>
                  <ul class="p-3 space-y-2">
                    <%= for name <- ["Jane", "David", "Emily", "Marco", "Anya", "You"] do %>
                      <li class="flex items-center justify-between rounded-lg border border-gray-800 px-3 py-2">
                        <div class="flex items-center gap-3">
                          <div class="h-7 w-7 rounded-full bg-zinc-700 text-gray-100 flex items-center justify-center text-[11px] font-semibold">
                            {String.first(name) |> String.upcase()}
                          </div>
                          <span class="text-sm text-gray-100">{name}</span>
                        </div>
                        <span class="flex items-center gap-1 text-xs text-gray-400">
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
                <% end %>
              </div>

              <%= if @active_panel_tab == :chat do %>
                <div class="p-3 border-t border-gray-800">
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      placeholder="Type a message…"
                      class="w-full bg-zinc-900/70 border border-gray-800 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-600"
                      disabled
                    />
                    <button
                      class="inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-zinc-800 text-gray-200"
                      disabled
                    >
                      Send
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
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
    {:noreply, stream_insert(socket, :messages, msg)}
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
    body = (body || "") |> String.trim()

    cond do
      # or flash: sign in to chat
      is_nil(user) ->
        {:noreply, socket}

      body == "" ->
        {:noreply, socket}

      true ->
        msg =
          Timesink.Comment.Theater.create_theater_comment!(%{
            content: body,
            assoc_id: theater_id,
            user_id: user.id
          })

        Phoenix.PubSub.broadcast(
          Timesink.PubSub,
          PubSubTopics.chat_topic(theater_id),
          {:new_message, msg}
        )

        {:noreply,
         socket
         |> assign(:chat_input, "")
         |> stream_insert(:messages, msg)}
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

    Enum.filter(
      [{:days, days}, {:hours, hours}, {:minutes, minutes}, {:seconds, seconds}],
      fn {_k, v} -> v > 0 end
    )
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
    time = Calendar.strftime(dt, "%-I:%M")
    ago = div(DateTime.diff(DateTime.utc_now(), dt, :hour), 1)
    "#{time} · #{ago}h"
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
