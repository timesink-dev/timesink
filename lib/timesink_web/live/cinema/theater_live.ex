defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film}
  alias TimesinkWeb.Components.FilmInfo
  alias TimesinkWeb.Components.TheaterPanel
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
       |> assign(:total_notes_count, 0)
       |> assign(:newly_surfaced_ids, MapSet.new())
       |> assign(:note_status_message, nil)
       |> assign(:note_moment_message, nil)
       |> assign(:just_posted_note_id, nil)
       |> assign(:freeze_notes?, false)
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
              <div class="text-center text-gray-400 text-xl py-8 border border-white/10 rounded-xl min-h-60 flex items-center justify-center bg-zinc-950/70">
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
                          if(label == :seconds and @pulse_seconds_only?,
                            do: " pulse-second text-neon-red-lightest",
                            else: ""
                          )
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
            <TheaterPanel.desktop_toolbar
              :if={is_nil(@open_panel)}
              notes_pulse={@notes_pulse}
              new_notes_count={@new_notes_count}
              total_notes_count={@total_notes_count}
              phase={@phase}
              offset={@offset}
            />
          </div>
          
    <!-- Mobile toolbar — below player, above film info -->
          <TheaterPanel.mobile_toolbar
            open_panel={@open_panel}
            notes_pulse={@notes_pulse}
            new_notes_count={@new_notes_count}
            total_notes_count={@total_notes_count}
            phase={@phase}
            offset={@offset}
          />

          <FilmInfo.film_info film={@film} />

          <div class="mt-12">
            <FilmInfo.film_review
              film={@film}
              review_url={TimesinkWeb.Endpoint.url() <> TimesinkWeb.Cinema.FilmLive.film_path(@film) <> "#film-review"}
            />
          </div>
        </div>
        
    <!-- Right: Desktop side panel -->
        <div class={[
          "hidden md:block shrink-0 transition-[opacity,width] duration-200 ease-out",
          if(is_nil(@open_panel),
            do: "w-0 opacity-0 translate-x-4 pointer-events-none",
            else: "w-96 opacity-100 translate-x-0"
          )
        ]}>
          <aside class="sticky top-20 self-start border border-white/10 rounded-2xl overflow-hidden bg-zinc-950/80 backdrop-blur-sm shadow-2xl">
            <div class="flex items-center justify-between px-4 py-3 border-b border-white/8">
              <TheaterPanel.panel_title
                open_panel={@open_panel}
                notes={@notes}
                total_notes_count={@total_notes_count}
              />
              <TheaterPanel.panel_actions
                open_panel={@open_panel}
                note_form_open={@note_form_open}
                phase={@phase}
                offset={@offset}
              />
            </div>
            <div id="theater-panel-desktop">
              <div class={@open_panel != :chat && "hidden"}>
                <TheaterPanel.chat_panel
                  chat_tab={@chat_tab}
                  has_messages?={@has_messages?}
                  streams={@streams}
                  typing_users={@typing_users}
                  presence={@presence}
                  chat_input={@chat_input}
                  list_id="chat-list"
                  scroll_id="chat-body-desktop"
                  host_id="theater-panel-desktop"
                  body_class="max-h-[40vh]"
                />
              </div>
              <div :if={@open_panel == :audience_notes}>
                <TheaterPanel.notes_panel
                  notes={@notes}
                  total_notes_count={@total_notes_count}
                  newly_surfaced_ids={@newly_surfaced_ids}
                  just_posted_note_id={@just_posted_note_id}
                  new_notes_count={@new_notes_count}
                  note_status_message={@note_status_message}
                  note_moment_message={@note_moment_message}
                  note_form_open={@note_form_open}
                  note_body={@note_body}
                  note_anchor_offset={@note_anchor_offset}
                  film={@film}
                  list_id="notes-list-desktop"
                  scroll_id="notes-body-desktop"
                  body_class="max-h-[40vh]"
                />
              </div>
              <div :if={@open_panel == :director_notes}>
                <TheaterPanel.director_panel />
              </div>
            </div>
          </aside>
        </div>
      </div>
      
    <!-- Mobile bottom sheet -->
      <div class={[
        "md:hidden fixed inset-0 z-50 flex items-end transition-opacity duration-200",
        if(@open_panel, do: "opacity-100 pointer-events-auto", else: "opacity-0 pointer-events-none")
      ]}>
        <div class="absolute inset-0 bg-black/70" phx-click="close_panel" aria-hidden="true"></div>

        <div class={[
          "relative w-full rounded-t-2xl border border-white/8 bg-zinc-950/95 backdrop-blur-sm transition-transform duration-300 ease-out flex flex-col",
          if(@open_panel, do: "translate-y-0", else: "translate-y-full")
        ]}>
          <div class="flex items-center justify-between px-4 py-3 border-b border-white/8 shrink-0">
            <TheaterPanel.panel_title
              open_panel={@open_panel}
              notes={@notes}
              total_notes_count={@total_notes_count}
            />
            <TheaterPanel.panel_actions
              open_panel={@open_panel}
              note_form_open={@note_form_open}
              phase={@phase}
              offset={@offset}
            />
          </div>

          <div class={["flex flex-col", @open_panel != :chat && "hidden"]}>
            <TheaterPanel.chat_panel
              chat_tab={@chat_tab}
              has_messages?={@has_messages?}
              streams={@streams}
              typing_users={@typing_users}
              presence={@presence}
              chat_input={@chat_input}
              list_id="mobile-chat-list"
              scroll_id="mobile-chat-body"
              host_id="mobile-chat-panel-wrap"
              body_class="h-[45vh]"
            />
          </div>

          <div :if={@open_panel == :audience_notes} id="mobile-chat-panel-wrap">
            <TheaterPanel.notes_panel
              notes={@notes}
              total_notes_count={@total_notes_count}
              newly_surfaced_ids={@newly_surfaced_ids}
              just_posted_note_id={@just_posted_note_id}
              new_notes_count={@new_notes_count}
              note_status_message={@note_status_message}
              note_moment_message={@note_moment_message}
              note_form_open={@note_form_open}
              note_body={@note_body}
              note_anchor_offset={@note_anchor_offset}
              film={@film}
              list_id="mobile-notes-list"
              scroll_id="mobile-chat-body"
              body_class="h-[45vh]"
            />
          </div>

          <div :if={@open_panel == :director_notes}>
            <TheaterPanel.director_panel />
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────
  # Tick / Presence / Phase
  # ───────────────────────────────────────────────────────────
  def handle_info(
        %{event: "tick", playback_state: %{phase: phase, offset: offset, countdown: countdown}},
        socket
      ) do
    time_parts = breakdown_time(countdown || 0)
    pulse_seconds_only? = Enum.all?(time_parts, fn {unit, _} -> unit == :seconds end)

    current_offset = offset || 0
    previous_offset = socket.assigns[:last_offset] || 0

    {notes, newly_surfaced_ids, total_notes_count} =
      if exhibition = socket.assigns[:exhibition] do
        total = Timesink.Cinema.Exhibition.Note.total_notes_count(exhibition.id)

        if socket.assigns.freeze_notes? or
             (phase != :playing and socket.assigns.open_panel == :audience_notes) do
          {
            socket.assigns.notes,
            MapSet.new(),
            total
          }
        else
          visible =
            Timesink.Cinema.Exhibition.Note.list_visible_notes(exhibition.id, current_offset)

          newly_surfaced =
            if current_offset > previous_offset do
              visible
              |> Enum.filter(fn n ->
                n.offset_seconds > previous_offset and n.offset_seconds <= current_offset
              end)
              |> MapSet.new(& &1.id)
            else
              MapSet.new()
            end

          {visible, newly_surfaced, total}
        end
      else
        {[], MapSet.new(), 0}
      end

    newly_unlocked_count = MapSet.size(newly_surfaced_ids)
    has_newly_unlocked? = newly_unlocked_count > 0
    should_pulse? = has_newly_unlocked? and socket.assigns.open_panel != :audience_notes

    if has_newly_unlocked? do
      Process.send_after(self(), :clear_new_notes_count, 4000)
    end

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:last_offset, current_offset)
     |> assign(:countdown, countdown)
     |> assign(:pulse_seconds_only?, pulse_seconds_only?)
     |> assign(:notes, notes)
     |> assign(:newly_surfaced_ids, newly_surfaced_ids)
     |> assign(:total_notes_count, total_notes_count)
     |> assign(
       :new_notes_count,
       if(has_newly_unlocked?,
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
    freeze? = phase != :playing and socket.assigns.open_panel == :audience_notes

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:countdown, countdown)
     |> assign(:freeze_notes?, freeze?)}
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

  def handle_info(:clear_note_status_message, socket) do
    {:noreply, assign(socket, :note_status_message, nil)}
  end

  def handle_info(:clear_note_moment_message, socket) do
    {:noreply, assign(socket, :note_moment_message, nil)}
  end

  def handle_info(:clear_new_notes_count, socket) do
    {:noreply,
     socket
     |> assign(:new_notes_count, 0)
     |> assign(:notes_pulse, false)}
  end

  def handle_info(:clear_just_posted_note, socket) do
    {:noreply, assign(socket, :just_posted_note_id, nil)}
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
          |> assign(:newly_surfaced_ids, MapSet.new())

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
          |> Timesink.Repo.preload(:user)

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
         |> assign(:newly_surfaced_ids, MapSet.new())
         |> assign(:note_moment_message, "#{format_offset(offset)}")
         |> push_event("toggle_body_scroll", %{prevent: true})}
    end
  end

  def handle_event("open_note_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:note_form_open, true)
     |> assign(:note_anchor_offset, socket.assigns.offset)}
  end

  def handle_event("cancel_note", _params, socket) do
    {:noreply,
     socket
     |> assign(:note_form_open, false)
     |> assign(:note_body, "")
     |> assign(:note_anchor_offset, nil)
     |> assign(:note_moment_message, nil)}
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
               source: :audience,
               body: body,
               offset_seconds: offset,
               status: :visible,
               exhibition_id: exhibition.id,
               user_id: user.id
             }) do
          {:ok, note} ->
            notes =
              Timesink.Cinema.Exhibition.Note.list_visible_notes(
                exhibition.id,
                socket.assigns.offset || 0
              )

            total = Timesink.Cinema.Exhibition.Note.total_notes_count(exhibition.id)

            film = socket.assigns.film
            theater = socket.assigns.theater

            Task.start(fn ->
              Timesink.Notifications.Discord.audience_note_posted(%{
                username: user.username,
                body: note.body,
                offset_seconds: note.offset_seconds,
                film_title: film.title,
                theater_name: theater.name
              })
            end)

            Process.send_after(self(), :clear_note_status_message, 2500)
            Process.send_after(self(), :clear_just_posted_note, 2500)

            {:noreply,
             socket
             |> assign(:notes, notes)
             |> assign(:total_notes_count, total)
             |> assign(:note_form_open, false)
             |> assign(:note_body, "")
             |> assign(:note_anchor_offset, nil)
             |> assign(:note_moment_message, nil)
             |> assign(
               :note_status_message,
               format_offset(offset)
             )
             |> assign(:just_posted_note_id, note.id)}

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

  def chat_time(%NaiveDateTime{} = ndt), do: chat_time(DateTime.from_naive!(ndt, "Etc/UTC"))

  def chat_time(%DateTime{} = dt) do
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
  def typing_line(typing_users, presence) do
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

  defp mux_thumbnail_url(nil, _offset), do: nil

  defp mux_thumbnail_url(playback_id, offset) when is_binary(playback_id) do
    seconds = offset |> trunc() |> max(0)

    "https://image.mux.com/#{playback_id}/thumbnail.jpg?time=#{seconds}&width=320&fit_mode=preserve"
  end

  def format_offset(nil), do: "00:00:00"

  def format_offset(total_seconds) when is_integer(total_seconds) do
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
