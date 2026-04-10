defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film}
  alias Timesink.Cinema.Exhibition.{Note}
  alias TimesinkWeb.Components.FilmInfo
  alias TimesinkWeb.PubSubTopics
  alias Timesink.Repo

  require Logger

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    socket =
      with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
           {:ok, showcase} <- Showcase.get_by(%{status: :active}),
           {:ok, exhibition} <-
             Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
           {:ok, film} <- Film.get(exhibition.film_id) do
        film = Repo.preload(film, [{:poster, [:blob]}, directors: [creative: [:user]]])
        poster_url = Timesink.Cinema.Film.poster_url(film.poster)

        og_description =
          if film.synopsis && film.synopsis != "",
            do: film.synopsis,
            else: "Watching live on TimeSink — Real audiences. Real time. Real cinema."

        assign(socket,
          page_title: film.title,
          og_title: film.title,
          og_description: og_description,
          og_image: poster_url,
          og_url: TimesinkWeb.Endpoint.url() <> "/now-playing/#{theater_slug}"
        )
      else
        _ -> socket
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(
        %{"theater_slug" => theater_slug},
        _uri,
        %{assigns: %{current_user: nil}} = socket
      ) do
    # Unauthenticated — redirect to the film preview page if a film is playing
    redirect_path =
      with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
           {:ok, showcase} <- Showcase.get_by(%{status: :active}),
           {:ok, exhibition} <-
             Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
           {:ok, film} <- Film.get(exhibition.film_id) do
        film = Repo.preload(film, directors: [creative: [:user]])
        TimesinkWeb.Cinema.FilmLive.film_path(film) <> "?from=theater"
      else
        _ -> "/sign-in"
      end

    {:noreply, push_navigate(socket, to: redirect_path)}
  end

  def handle_params(%{"theater_slug" => theater_slug}, _uri, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      # Clean up previous theater subscriptions if this is a theater change
      if old_theater = socket.assigns[:theater] do
        if old_theater.id != theater.id do
          Phoenix.PubSub.unsubscribe(Timesink.PubSub, PubSubTopics.chat_topic(old_theater.id))

          Phoenix.PubSub.unsubscribe(
            Timesink.PubSub,
            PubSubTopics.scheduler_topic(old_theater.id)
          )

          Phoenix.PubSub.unsubscribe(Timesink.PubSub, PubSubTopics.presence_topic(old_theater.id))
        end
      end

      exhibition = Repo.preload(exhibition, [:showcase, :theater])

      film =
        Repo.preload(film, [
          {:video, [:blob]},
          {:poster, [:blob]},
          :genres,
          directors: [creative: [:user]],
          cast: [creative: [:user]],
          writers: [creative: [:user]],
          producers: [creative: [:user]],
          crew: [creative: [:user]]
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

      poster_url = Timesink.Cinema.Film.poster_url(film.poster)

      og_description =
        if film.synopsis && film.synopsis != "",
          do: film.synopsis,
          else: "Watching live on TimeSink — Real audiences. Real time. Real cinema."

      {:noreply,
       socket
       |> stream(:messages, recent_msgs, reset: true)
       |> assign(:chat_input, "")
       |> assign(:typing_users, %{})
       |> assign(:theater, theater)
       |> assign(:exhibition, exhibition)
       |> assign(:film, film)
       |> assign(:user, socket.assigns.current_user)
       |> assign(:presence, presence)
       |> assign(:offset, nil)
       |> assign(:last_offset, nil)
       |> assign(:phase, nil)
       |> assign(:countdown, nil)
       |> assign(:pulse_seconds_only?, false)
       # notes
       |> assign(:notes, [])
       |> assign(:note_body, "")
       |> assign(:note_form_open, false)
       |> assign(:note_anchor_offset, nil)
       |> assign(:new_notes_count, 0)
       |> assign(:notes_pulse, false)
       # UI state
       |> assign(:open_panel, nil)
       |> assign(:chat_tab, :messages)
       |> assign(:has_messages?, length(recent_msgs) > 0)
       # seo stuff
       |> assign(:page_title, film.title)
       |> assign(:og_title, film.title)
       |> assign(:og_description, og_description)
       |> assign(:og_image, poster_url)
       |> assign(:og_url, TimesinkWeb.Endpoint.url() <> "/now-playing/#{theater.slug}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
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

      <%!-- <!-- Toolbar -->
      <div class="flex justify-between items-center mb-4">
        <div></div>

        <div class="flex items-center gap-3">
          <!-- Save Moment -->
          <div class="group relative inline-block">
            <button
              phx-click="mark_moment"
              disabled={@phase != :playing or is_nil(@offset)}
              class={[
                "inline-flex items-center gap-2 text-sm px-4 py-2 rounded-lg border transition",
                if(@phase == :playing and not is_nil(@offset),
                  do:
                    "cursor-pointer border-white/10 bg-white/2 hover:bg-white/6 text-gray-300 hover:text-white",
                  else: "cursor-not-allowed border-white/5 bg-white/[0.02] text-zinc-500"
                )
              ]}
            >
              <.icon name="hero-star" class="w-4 h-4" />
              <span>Capture moment</span>
            </button>

    <!-- Tooltip ABOVE -->
            <div
              :if={@phase != :playing or is_nil(@offset)}
              class="pointer-events-none absolute left-1/2 -translate-x-1/2 bottom-full mb-2 hidden group-hover:block z-10"
            >
              <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                Only available while the film is playing
                <div class="absolute left-1/2 -translate-x-1/2 top-full w-2 h-2 bg-zinc-900 border-r border-b border-white/10 rotate-45">
                </div>
              </div>
            </div>
          </div>
          <!-- Show Chat -->
          <button
            phx-click="toggle_chat"
            class={[
              @open_panel && "invisible md:visible",
              "cursor-pointer text-sm px-4 py-2 rounded-lg border border-white/10 bg-white/2 hover:bg-white/6 text-gray-300 hover:text-white transition"
            ]}
          >
            {if @open_panel, do: "Hide Chat", else: "Show Chat"}
          </button>
        </div>
      </div> --%>
      
    <!-- Main layout (mobile-first: stacked) -->
      <div class="flex flex-col md:flex-row md:gap-6 md:items-start">
        <!-- Left: Player + Film Info -->
        <div class="min-w-0 md:flex-1 transition-all duration-300">
          <% playback_id = Film.get_mux_playback_id(@film.video) %>

          <div class="relative mx-auto w-full max-w-[920px]">
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
            <% else %>
              <div class="text-center text-gray-400 text-xl py-8 border border-white/10 rounded-xl bg-white/2 min-h-60 flex items-center justify-center">
                <%= if is_nil(@countdown) do %>
                  <div class="flex flex-col items-center justify-center gap-2 text-gray-400">
                    <h3 class="font-semibold">Finding your seat...</h3>
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
                  if(label == :seconds and @pulse_seconds_only?, do: " pulse-second text-neon-red-lightest", else: "")
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
            
    <!-- Desktop floating toolbar -->
            <div
              :if={is_nil(@open_panel)}
              class="hidden md:flex absolute top-0 left-full ml-3 z-20 flex-col gap-2"
            >
              <div class="group relative">
                <button
                  phx-click="open_panel"
                  phx-value-panel="chat"
                  aria-label="Open live chat"
                  class="cursor-pointer h-10 w-10 rounded-lg border border-white/10 bg-zinc-900/80 text-zinc-200 hover:bg-zinc-800 hover:text-white flex items-center justify-center transition"
                >
                  <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                </button>

                <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
                  <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                    Live chat
                    <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
                    </div>
                  </div>
                </div>
              </div>

              <div class="group relative">
                <button
                  phx-click="open_panel"
                  phx-value-panel="audience_notes"
                  aria-label="Open audience notes"
                  class={[
                    "cursor-pointer h-10 w-10 rounded-lg border flex items-center justify-center transition bg-zinc-900/80 hover:bg-zinc-800 hover:text-white",
                    @notes_pulse && "border-white/20 text-white",
                    !@notes_pulse && "border-white/10 text-zinc-200"
                  ]}
                >
                  <.icon name="hero-folder-open" class="w-4 h-4" />
                </button>

                <%= if @new_notes_count > 0 do %>
                  <span class="absolute -top-1 -right-1 inline-flex min-w-5 h-5 items-center justify-center rounded-full bg-white/10 px-1 text-[10px] text-white">
                    {@new_notes_count}
                  </span>
                <% end %>

                <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
                  <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                    Audience notes
                    <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
                    </div>
                  </div>
                </div>
              </div>

              <%!-- <div class="group relative">
                <button
                  phx-click="open_panel"
                  phx-value-panel="live_audience"
                  aria-label="Open live audience"
                  class="cursor-pointer h-10 w-10 rounded-lg border border-white/10 bg-zinc-900/80 text-zinc-200 hover:bg-zinc-800 hover:text-white flex items-center justify-center transition"
                >
                  <.icon name="hero-users" class="w-4 h-4" />
                </button>

                <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
                  <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                    Live audience
                    <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
                    </div>
                  </div>
                </div>
              </div> --%>
              <div class="group relative">
                <button
                  phx-click="open_panel"
                  phx-value-panel="live_audience"
                  aria-label="Open live audience"
                  class="cursor-pointer h-10 w-10 rounded-lg border border-white/10 bg-zinc-900/80 text-zinc-200 hover:bg-zinc-800 hover:text-white flex items-center justify-center transition"
                >
                  <.icon name="hero-megaphone" class="w-4 h-4" />
                </button>

                <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
                  <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                    Director's commentary
                    <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
                    </div>
                  </div>
                </div>
              </div>
              <div class="group relative">
                <button
                  phx-click="mark_moment"
                  aria-label="Mark a moment"
                  F
                  disabled={@phase != :playing or is_nil(@offset)}
                  class={[
                    "inline-flex items-center gap-2 text-sm h-10 w-10 px-3 py-2 rounded-lg border transition",
                    if(@phase == :playing and not is_nil(@offset),
                      do:
                        "cursor-pointer border-neon-blue-lightest bg-white/2 hover:bg-white/6 text-gray-300 hover:text-white",
                      else: "cursor-not-allowed border-white/5 bg-white/2 text-zinc-500"
                    )
                  ]}
                >
                  <.icon name="hero-bookmark" class="w-4 h-4 text-neon-blue-light" />
                </button>

                <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
                  <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                    Save a timestamp to make a note
                    <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- <div class="mt-4 flex items-center justify-end">
            <button
              phx-click="mark_moment"
              class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm border border-white/10 bg-white/4 text-gray-200 hover:bg-white/8 transition"
              disabled={@phase != :playing or is_nil(@offset)}
            >
              ✏︎ Mark moment
            </button>
          </div> --%>

          <FilmInfo.film_info film={@film} />

          <div class="mt-12">
            <FilmInfo.film_review
              film={@film}
              review_url={TimesinkWeb.Endpoint.url() <> TimesinkWeb.Cinema.FilmLive.film_path(@film) <> "#film-review"}
            />
          </div>
        </div>
        
    <!-- Right: Desktop side panel -->
        <aside class={[
          "hidden md:block md:sticky md:top-20 md:self-start border border-white/10 rounded-2xl overflow-hidden bg-white/[0.02] md:transform-gpu transition-all duration-200",
          if(is_nil(@open_panel),
            do: "opacity-0 md:w-0 md:translate-x-4 pointer-events-none",
            else: "opacity-100 md:w-96 md:translate-x-0"
          )
        ]}>
          <div class="flex items-center justify-between bg-white/3 px-4 py-3 border-b border-white/10">
            <div class="text-sm text-white font-medium">
              <%= case @open_panel do %>
                <% :chat -> %>
                  Live Chat
                <% :audience_notes -> %>
                  Audience Notes
                <% :director_notes -> %>
                  Director’s Notes
                <% _ -> %>
              <% end %>
            </div>

            <button
              phx-click="close_panel"
              class="cursor-pointer inline-flex h-8 w-8 items-center justify-center rounded-md text-zinc-400 hover:text-white hover:bg-white/[0.06] transition"
              aria-label="Close panel"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>

          <div id="theater-panel-desktop" class="bg-white/1 relative">
            <div :if={@open_panel == :chat}>
              <div class="flex items-center gap-6 px-4 py-3 border-b border-white/10 bg-white/[0.02] text-sm">
                <button
                  phx-click="switch_chat_tab"
                  phx-value-to="messages"
                  class={[
                    "pb-2 cursor-pointer",
                    @chat_tab == :messages && "text-white border-b-2 border-white",
                    @chat_tab != :messages && "text-gray-400 hover:text-gray-200"
                  ]}
                >
                  Chat
                </button>

                <button
                  phx-click="switch_chat_tab"
                  phx-value-to="audience"
                  class={[
                    "pb-2 cursor-pointer",
                    @chat_tab == :audience && "text-white border-b-2 border-white",
                    @chat_tab != :audience && "text-gray-400 hover:text-gray-200"
                  ]}
                >
                  Live Audience
                </button>
              </div>

              <div :if={@chat_tab == :messages}>
                <div id="chat-body-desktop" class="max-h-[40vh] overflow-y-auto relative">
                  <%= if not @has_messages? do %>
                    <div class="flex items-center justify-center h-full min-h-[200px] px-4 py-8">
                      <div class="text-center">
                        <div class="text-zinc-400 text-sm mb-2">No messages yet</div>
                        <div class="text-zinc-500 text-xs">
                          Be the first to start the conversation!
                        </div>
                      </div>
                    </div>
                  <% else %>
                    <ul
                      id="chat-list"
                      phx-update="stream"
                      phx-hook="ChatAutoScroll"
                      data-scroll="#chat-body-desktop"
                      data-host="#theater-panel-desktop"
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

                  <%= if map_size(@typing_users) > 0 do %>
                    <div class="px-4 py-2 text-xs text-zinc-400 border-t border-white/5">
                      {typing_line(@typing_users, @presence)}
                    </div>
                  <% end %>
                </div>

                <form phx-submit="chat:send" class="p-3 border-t border-white/10">
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      name="chat[body]"
                      value={@chat_input}
                      placeholder="Type a message…"
                      phx-change="chat:typing"
                      phx-debounce="100"
                      class="w-full bg-white/4 border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20"
                      autocomplete="off"
                    />
                    <button class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-white/6 text-gray-200 hover:bg-white/[0.10] transition">
                      Send
                    </button>
                  </div>
                </form>
              </div>

              <div :if={@chat_tab == :audience} class="max-h-[65vh] overflow-y-auto p-3">
                <%= if map_size(@presence) > 0 do %>
                  <ul class="space-y-2">
                    <%= for {_user_id, %{metas: [meta | _]}} <- @presence do %>
                      <li class="flex items-center justify-between rounded-lg border border-white/10 px-3 py-2 bg-white/[0.02] hover:bg-white/[0.04] transition">
                        <div class="flex items-center gap-3">
                          <div class="h-7 w-7 rounded-full bg-white/8 text-gray-100 flex items-center justify-center text-[11px] font-semibold">
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

            <div :if={@open_panel == :audience_notes}>
              <div class="max-h-[65vh] overflow-y-auto p-4 space-y-4">
                <div class="flex items-center justify-between gap-3">
                  <%!-- <div>
                    <h3 class="text-sm font-medium text-white">Audience Notes</h3>
                    <p class="text-xs text-zinc-400 mt-1">
                      Notes surface only when their moment is reached.
                    </p>
                  </div> --%>

                  <div class="flex items-center gap-2">
                    <div class="group relative">
                      <div
                        :if={@phase != :playing or is_nil(@offset)}
                        class="pointer-events-none absolute left-1/2 -translate-x-1/2 bottom-full mb-2 hidden group-hover:block z-10"
                      >
                        <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
                          Only available while the film is playing
                          <div class="absolute left-1/2 -translate-x-1/2 top-full w-2 h-2 bg-zinc-900 border-r border-b border-white/10 rotate-45">
                          </div>
                        </div>
                      </div>
                    </div>

                    <button
                      phx-click="open_note_form"
                      class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-xs bg-white/6 text-gray-200 hover:bg-white/10 transition"
                    >
                      <.icon name="hero-document-plus" class="w-4 h-4" />
                    </button>
                  </div>
                </div>

                <%= if @note_form_open do %>
                  <form
                    phx-submit="note:save"
                    phx-change="note:change"
                    class="rounded-xl border border-white/10 bg-white/3 p-3 space-y-3"
                  >
                    <div class="text-xs text-zinc-400">
                      Adding note for: {format_offset(@note_anchor_offset)}
                    </div>

                    <textarea
                      name="note[body]"
                      rows="3"
                      class="w-full bg-white/4 border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20"
                      placeholder="Post a note for this moment…"
                    ><%= @note_body %></textarea>

                    <div class="flex items-center justify-end gap-2">
                      <button
                        type="button"
                        phx-click="cancel_note"
                        class="cursor-pointer rounded-lg px-3 py-2 text-xs text-zinc-300 hover:text-white"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-xs bg-white/6 text-gray-200 hover:bg-white/10 transition"
                      >
                        Post
                      </button>
                    </div>
                  </form>
                <% end %>

                <%= if Enum.empty?(@notes) do %>
                  <div class="text-center text-zinc-400 text-sm py-8">
                    No notes have surfaced yet.
                  </div>
                <% else %>
                  <div class="space-y-3">
                    <%= for note <- @notes do %>
                      <div class="rounded-xl border border-white/10 bg-white/2 p-3">
                        <div class="flex items-center justify-between gap-3">
                          <span class="text-xs text-zinc-400">
                            {(note.user && "@" <> note.user.username) || "Member"}
                          </span>
                          <span class="text-xs text-zinc-500">
                            {format_offset(note.offset_seconds)}
                          </span>
                        </div>

                        <p class="text-sm text-gray-100 mt-2 whitespace-pre-wrap">{note.body}</p>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
            <div :if={@open_panel == :director_notes} class="p-4">
              <div class="text-sm text-zinc-400">
                Director’s commentary is not available for this screening yet.
              </div>
            </div>
          </div>
        </aside>
      </div>
      
    <!-- Mobile chat drawer -->
      <div class={[
        "md:hidden fixed inset-0 z-50 flex items-end transition-opacity duration-200",
        if(@open_panel, do: "opacity-100 pointer-events-auto", else: "opacity-0 pointer-events-none")
      ]}>
        <!-- backdrop -->
        <div class="absolute inset-0 bg-black/70" phx-click="toggle_chat" aria-hidden="true"></div>
        
    <!-- sheet -->
        <div class={[
          "relative w-full rounded-t-2xl border-t border-white/10 bg-backroom-black transition-transform duration-300 ease-out",
          if(@open_panel, do: "translate-y-0", else: "translate-y-full")
        ]}>
          <div class="flex items-center justify-between px-4 py-3 border-b border-white/10">
            <div class="flex gap-4 text-sm">
              <button
                phx-click="switch_tab"
                phx-value-to="chat"
                class={[
                  "pb-2 cursor-pointer",
                  @open_panel == :chat && "text-white border-b-2 border-white",
                  @open_panel != :chat && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Chat
              </button>
              <button
                phx-click="switch_tab"
                phx-value-to="online"
                class={[
                  "pb-2 cursor-pointer",
                  @open_panel == :online && "text-white border-b-2 border-white",
                  @open_panel != :online && "text-gray-400 hover:text-gray-200"
                ]}
              >
                Live Audience
              </button>
            </div>
            <button class="text-gray-300" phx-click="toggle_chat" aria-label="Close">✕</button>
          </div>

          <div id="mobile-chat-panel" class="h-[50vh] flex flex-col relative">
            <div id="mobile-chat-body" class="flex-1 overflow-y-auto overscroll-contain">
              <div class={@open_panel == :chat || "hidden"}>
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
                @open_panel == :online || "hidden"
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

            <%= if @open_panel == :chat do %>
              <form phx-submit="chat:send" class="p-3 border-t border-white/10 bg-backroom-black">
                <div class="flex items-center gap-2">
                  <input
                    type="text"
                    name="chat[body]"
                    value={@chat_input}
                    placeholder="Type a message…"
                    phx-change="chat:typing"
                    phx-debounce="100"
                    class="w-full bg-white/4 border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20"
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

    current_offset = offset || 0
    previous_offset = socket.assigns[:last_offset] || 0

    notes =
      if exhibition = socket.assigns[:exhibition] do
        Timesink.Cinema.Exhibition.Note.list_visible_notes(exhibition.id, current_offset)
      else
        []
      end

    newly_unlocked_count =
      cond do
        is_nil(socket.assigns[:exhibition]) ->
          0

        current_offset <= previous_offset ->
          0

        true ->
          Enum.count(notes, fn note ->
            note.offset_seconds > previous_offset and note.offset_seconds <= current_offset
          end)
      end

    should_pulse? =
      newly_unlocked_count > 0 and socket.assigns.open_panel != :audience_notes

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:last_offset, current_offset)
     |> assign(:countdown, countdown)
     |> assign(:pulse_seconds_only?, pulse_seconds_only?)
     |> assign(:notes, notes)
     |> assign(
       :new_notes_count,
       if(should_pulse?,
         do: socket.assigns.new_notes_count + newly_unlocked_count,
         else: socket.assigns.new_notes_count
       )
     )
     |> assign(:notes_pulse, should_pulse?)}
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

  def handle_event("open_panel", %{"panel" => panel}, socket) do
    open_panel =
      case panel do
        "chat" -> :chat
        "audience_notes" -> :audience_notes
        "director_notes" -> :director_notes
        _ -> nil
      end

    socket =
      socket
      |> assign(:open_panel, open_panel)
      |> push_event("toggle_body_scroll", %{prevent: not is_nil(open_panel)})

    socket =
      case open_panel do
        :audience_notes ->
          socket
          |> assign(:new_notes_count, 0)
          |> assign(:notes_pulse, false)

        :chat ->
          assign(socket, :chat_tab, :messages)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("close_panel", _params, socket) do
    {:noreply,
     socket
     |> assign(:open_panel, nil)
     |> push_event("toggle_body_scroll", %{prevent: false})}
  end

  def handle_event("open_panel", %{"panel" => panel}, socket) do
    open_panel =
      case panel do
        "chat" -> :chat
        "audience_notes" -> :audience_notes
        "director_notes" -> :director_notes
        _ -> nil
      end

    socket =
      socket
      |> assign(:open_panel, open_panel)
      |> push_event("toggle_body_scroll", %{prevent: not is_nil(open_panel)})

    socket =
      case open_panel do
        :audience_notes ->
          socket
          |> assign(:new_notes_count, 0)
          |> assign(:notes_pulse, false)

        :chat ->
          assign(socket, :chat_tab, :messages)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("switch_chat_tab", %{"to" => to}, socket) do
    tab =
      case to do
        "audience" -> :audience
        _ -> :messages
      end

    {:noreply, assign(socket, :chat_tab, tab)}
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
  # Note event handlers
  # ───────────────────────────────────────────────────────────
  def handle_event("mark_moment", _params, socket) do
    offset = socket.assigns.offset

    cond do
      is_nil(offset) ->
        {:noreply, socket}

      true ->
        {:noreply,
         socket
         |> assign(:note_form_open, true)
         |> assign(:note_anchor_offset, offset)
         |> assign(:open_panel, :audience_notes)
         |> assign(:new_notes_count, 0)
         |> assign(:notes_pulse, false)
         |> push_event("toggle_body_scroll", %{prevent: true})}
    end
  end

  def handle_event("open_note_form", _params, socket) do
    offset = socket.assigns.note_anchor_offset || socket.assigns.offset

    {:noreply,
     socket
     |> assign(:note_form_open, true)
     |> assign(:note_anchor_offset, offset)}
  end

  def handle_event("cancel_note", _params, socket) do
    {:noreply,
     socket
     |> assign(:note_form_open, false)
     |> assign(:note_body, "")}
  end

  def handle_event("note:change", %{"note" => %{"body" => body}}, socket) do
    {:noreply, assign(socket, :note_body, body)}
  end

  def handle_event("note:save", %{"note" => %{"body" => body}}, socket) do
    user = socket.assigns.user
    exhibition = socket.assigns.exhibition
    offset = socket.assigns.note_anchor_offset
    body = String.trim(body || "")

    cond do
      is_nil(user) or is_nil(exhibition) or is_nil(offset) ->
        {:noreply, socket}

      body == "" ->
        {:noreply, socket}

      true ->
        case Timesink.Cinema.Note.create(%{
               source: :live_audience,
               body: body,
               offset_seconds: offset,
               status: :visible,
               exhibition_id: exhibition.id,
               user_id: user.id
             }) do
          {:ok, _note} ->
            notes =
              Timesink.Cinema.Exhibition.Note.list_visible_notes(
                exhibition.id,
                socket.assigns.offset || 0
              )

            {:noreply,
             socket
             |> assign(:notes, notes)
             |> assign(:note_form_open, false)
             |> assign(:note_body, "")
             |> assign(:note_anchor_offset, nil)}

          {:error, changeset} ->
            Logger.warning("Failed to create note: #{inspect(changeset.errors)}")
            {:noreply, socket}
        end
    end
  end

  # ───────────────────────────────────────────────────────────
  # Helpers
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

  defp format_offset(nil), do: "00:00:00"

  defp format_offset(total_seconds) when is_integer(total_seconds) do
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    [
      String.pad_leading(to_string(hours), 2, "0"),
      String.pad_leading(to_string(minutes), 2, "0"),
      String.pad_leading(to_string(seconds), 2, "0")
    ]
    |> Enum.join(":")
  end
end
