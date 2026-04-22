defmodule TimesinkWeb.Components.TheaterPanel do
  use TimesinkWeb, :html
  alias Timesink.Cinema.Film

  # ── Shared helpers ─────────────────────────────────────────

  attr :open_panel, :atom, required: true
  attr :notes, :list, required: true
  attr :total_notes_count, :integer, required: true
  attr :director_commentary, :list, default: []

  def panel_title(assigns) do
    ~H"""
    <div class="text-xs font-semibold uppercase tracking-widest text-zinc-400">
      <%= case @open_panel do %>
        <% :chat -> %>
          Live Chat
        <% :audience_notes -> %>
          <span class="flex items-center gap-2">
            <span>Audience Notes</span>
            <%= if @total_notes_count > 0 do %>
              <span>·</span>
              <span class="text-[10px] font-normal tracking-normal text-zinc-500">
                {length(@notes)} of {@total_notes_count}
              </span>
            <% end %>
          </span>
        <% :director_notes -> %>
          <span class="flex items-center gap-2 text-amber-400/80">
            <span>Director's Commentary</span>
            <%= if length(@director_commentary) > 0 do %>
              <span class="text-[10px] font-normal tracking-normal text-amber-600/60">
                · {length(@director_commentary)}
              </span>
            <% end %>
          </span>
        <% _ -> %>
      <% end %>
    </div>
    """
  end

  attr :open_panel, :atom, required: true
  attr :note_form_open, :boolean, required: true
  attr :phase, :atom, required: true
  attr :offset, :any, required: true

  def panel_actions(assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <%= if @open_panel == :audience_notes and not @note_form_open do %>
        <div class="group relative">
          <button
            phx-click="open_note_form"
            aria-label="Add a note"
            disabled={@phase != :playing or is_nil(@offset)}
            class={[
              "inline-flex h-8 w-8 items-center justify-center rounded-md transition",
              if(@phase == :playing and not is_nil(@offset),
                do: "cursor-pointer text-zinc-400 hover:bg-white/8",
                else: "text-zinc-600 cursor-not-allowed"
              )
            ]}
          >
            <.icon name="hero-pencil-square" class="w-4 h-4" />
          </button>
          <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
            <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
              <%= if @phase == :playing and not is_nil(@offset) do %>
                Add a note at this moment
              <% else %>
                Only available while the film is playing
              <% end %>
              <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
              </div>
            </div>
          </div>
        </div>
      <% end %>
      <button
        phx-click="close_panel"
        class="cursor-pointer inline-flex h-8 w-8 items-center justify-center rounded-md text-zinc-400 hover:text-white hover:bg-white/6 transition"
        aria-label="Close panel"
      >
        <.icon name="hero-x-mark" class="w-4 h-4" />
      </button>
    </div>
    """
  end

  # ── Toolbars ───────────────────────────────────────────────

  attr :notes_pulse, :boolean, required: true
  attr :new_notes_count, :integer, required: true
  attr :total_notes_count, :integer, required: true
  attr :total_director_commentary_count, :integer, required: true
  attr :phase, :atom, required: true
  attr :offset, :any, required: true

  def desktop_toolbar(assigns) do
    ~H"""
    <div class="hidden md:flex absolute top-0 left-full ml-3 z-20 flex-col gap-1 rounded-xl border border-white/8 bg-zinc-950/70 backdrop-blur-sm p-1 shadow-xl">
      <div class="group relative">
        <button
          phx-click="open_panel"
          phx-value-panel="chat"
          aria-label="Open live chat"
          class="cursor-pointer h-9 w-9 rounded-lg border border-transparent text-zinc-400 hover:bg-white/8 hover:text-white flex items-center justify-center transition"
        >
          <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
        </button>
        <.toolbar_tooltip label="Live chat" />
      </div>
      <div class="group relative">
        <button
          phx-click="open_panel"
          phx-value-panel="audience_notes"
          aria-label="Open audience notes"
          class={[
            "cursor-pointer h-9 w-9 rounded-lg border border-transparent flex items-center justify-center transition relative",
            if(@notes_pulse,
              do: "text-white bg-white/8 ring-1 ring-white/15",
              else: "text-zinc-400 hover:bg-white/8 hover:text-white"
            )
          ]}
        >
          <.icon name="hero-folder-open" class="w-4 h-4" />
        </button>
        <.notes_badge new_count={@new_notes_count} total={@total_notes_count} />
        <.toolbar_tooltip label="Audience notes" />
      </div>
      <div class="group relative">
        <button
          phx-click="open_panel"
          phx-value-panel="director_notes"
          aria-label="Director's commentary"
          class="cursor-pointer h-9 w-9 rounded-lg border border-transparent text-zinc-400 hover:bg-white/8 hover:text-white flex items-center justify-center transition relative"
        >
          <.icon name="hero-megaphone" class="w-4 h-4" />
          <%= if @total_director_commentary_count > 0 do %>
            <span class="absolute -top-1 -right-1 inline-flex min-w-4 h-4 items-center justify-center rounded-full bg-amber-500/15 border border-amber-500/30 px-1 text-[9px] font-semibold leading-none text-amber-400">
              {@total_director_commentary_count}
            </span>
          <% end %>
        </button>
        <.toolbar_tooltip label="Director's commentary" />
      </div>
      <div class="my-0.5 border-t border-white/8"></div>
      <div class="group relative">
        <button
          phx-click="mark_moment"
          aria-label="Mark a moment"
          disabled={@phase != :playing or is_nil(@offset)}
          class={[
            "inline-flex items-center justify-center h-9 w-9 rounded-lg border border-transparent transition",
            if(@phase == :playing and not is_nil(@offset),
              do: "cursor-pointer text-zinc-400 hover:bg-white/8",
              else: "cursor-not-allowed text-zinc-600"
            )
          ]}
        >
          <.icon name="hero-pencil-square" class="w-4 h-4" />
        </button>
        <.toolbar_tooltip label="Pin this moment & share a note" />
      </div>
    </div>
    """
  end

  attr :open_panel, :atom, required: true
  attr :notes_pulse, :boolean, required: true
  attr :new_notes_count, :integer, required: true
  attr :total_notes_count, :integer, required: true
  attr :total_director_commentary_count, :integer, required: true
  attr :phase, :atom, required: true
  attr :offset, :any, required: true

  def mobile_toolbar(assigns) do
    ~H"""
    <div class="md:hidden flex items-center gap-1 mt-3 rounded-xl border border-white/8 bg-zinc-950/70 backdrop-blur-sm p-1">
      <button
        phx-click="open_panel"
        phx-value-panel="chat"
        aria-label="Open live chat"
        class={[
          "flex-1 flex items-center justify-center gap-1 h-9 rounded-lg border border-transparent text-xs transition",
          if(@open_panel == :chat,
            do: "bg-white/10 text-white",
            else: "text-zinc-400 hover:text-white"
          )
        ]}
      >
        <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
        <span>Chat</span>
      </button>
      <button
        phx-click="open_panel"
        phx-value-panel="audience_notes"
        aria-label="Open audience notes"
        class={[
          "flex-1 flex items-center justify-center h-9 rounded-lg border border-transparent text-xs transition",
          if(@open_panel == :audience_notes,
            do: "bg-white/10 text-white",
            else: if(@notes_pulse, do: "text-white", else: "text-zinc-400 hover:text-white")
          )
        ]}
      >
        <span class="relative inline-flex items-center gap-1">
          <.icon name="hero-folder-open" class="w-4 h-4" />
          <span>Notes</span>
          <.notes_badge new_count={@new_notes_count} total={@total_notes_count} mobile />
        </span>
      </button>
      <button
        phx-click="open_panel"
        phx-value-panel="director_notes"
        aria-label="Director's commentary"
        class={[
          "flex-1 flex items-center justify-center gap-1 h-9 rounded-lg border border-transparent text-xs transition",
          if(@open_panel == :director_notes,
            do: "bg-white/10 text-white",
            else: "text-zinc-400 hover:text-white"
          )
        ]}
      >
        <span class="relative inline-flex items-center gap-1">
          <.icon name="hero-megaphone" class="w-4 h-4" />
          <span>Director</span>
          <%= if @total_director_commentary_count > 0 do %>
            <span class="absolute -top-3 -right-4 inline-flex min-w-4 h-4 items-center justify-center rounded-full bg-amber-500/15 border border-amber-500/30 px-1 text-[9px] font-semibold leading-none text-amber-400">
              {@total_director_commentary_count}
            </span>
          <% end %>
        </span>
      </button>
      <div class="w-px h-5 bg-white/8 shrink-0"></div>
      <button
        phx-click="mark_moment"
        aria-label="Mark a moment"
        disabled={@phase != :playing or is_nil(@offset)}
        class={[
          "flex-1 flex items-center justify-center gap-2 h-9 rounded-lg border border-transparent text-xs transition",
          if(@phase == :playing and not is_nil(@offset),
            do: "cursor-pointer text-zinc-400 hover:bg-white/8",
            else: "cursor-not-allowed text-zinc-600"
          )
        ]}
      >
        <.icon name="hero-pencil-square" class="w-4 h-4" />
        <span>Pin</span>
      </button>
    </div>
    """
  end

  # ── Private function components ─────────────────────────────

  attr :label, :string, default: nil
  slot :inner_block

  defp toolbar_tooltip(assigns) do
    ~H"""
    <div class="pointer-events-none absolute right-full top-1/2 -translate-y-1/2 mr-2 hidden group-hover:block z-10">
      <div class="relative whitespace-nowrap rounded-md border border-white/10 bg-zinc-900 px-3 py-2 text-xs text-zinc-300 shadow-lg">
        <%= if @label do %>
          {@label}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
        <div class="absolute left-full top-1/2 -translate-y-1/2 -ml-1 w-2 h-2 bg-zinc-900 border-t border-r border-white/10 rotate-45">
        </div>
      </div>
    </div>
    """
  end

  attr :new_count, :integer, required: true
  attr :total, :integer, required: true
  attr :mobile, :boolean, default: false

  defp notes_badge(assigns) do
    ~H"""
    <%= if @new_count > 0 do %>
      <span class={[
        "inline-flex min-w-4 h-4 items-center justify-center rounded-full bg-white/15 border border-white/30 px-1 text-[9px] font-semibold leading-none text-white",
        if(@mobile, do: "absolute -top-3 -right-4", else: "absolute -top-1 -right-1")
      ]}>
        +{@new_count}
      </span>
    <% else %>
      <%= if @total > 0 do %>
        <span class={[
          "inline-flex min-w-4 h-4 items-center justify-center rounded-full bg-zinc-600/30 border border-zinc-500/30 px-1 text-[9px] leading-none text-zinc-400",
          if(@mobile, do: "absolute -top-3 -right-4", else: "absolute -top-1 -right-1")
        ]}>
          {@total}
        </span>
      <% end %>
    <% end %>
    """
  end

  # ── Chat ───────────────────────────────────────────────────

  attr :chat_tab, :atom, required: true
  attr :has_messages?, :boolean, required: true
  attr :streams, :map, required: true
  attr :typing_users, :map, required: true
  attr :presence, :map, required: true
  attr :chat_input, :string, required: true
  attr :list_id, :string, required: true
  attr :scroll_id, :string, required: true
  attr :host_id, :string, required: true
  attr :body_class, :string, default: "max-h-[40vh]"

  def chat_panel(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-6 px-4 py-3 border-b border-white/8 bg-zinc-900/30 text-sm shrink-0">
        <button
          phx-click="switch_chat_tab"
          phx-value-to="messages"
          class={[
            "pb-1 cursor-pointer",
            @chat_tab == :messages && "text-white border-b-2 border-white",
            @chat_tab != :messages && "text-zinc-400 hover:text-gray-200"
          ]}
        >
          Chat
        </button>
        <button
          phx-click="switch_chat_tab"
          phx-value-to="audience"
          class={[
            "pb-1 cursor-pointer",
            @chat_tab == :audience && "text-white border-b-2 border-white",
            @chat_tab != :audience && "text-zinc-400 hover:text-gray-200"
          ]}
        >
          Live Audience
        </button>
      </div>

      <div class={[
        @body_class,
        "overflow-y-auto overscroll-contain relative",
        @chat_tab != :messages && "hidden"
      ]}>
        <div :if={not @has_messages?} class="flex items-center justify-center min-h-40 px-6 py-8">
          <div class="text-center">
            <div class="text-zinc-400 text-sm mb-1">The room is quiet.</div>
            <div class="text-zinc-600 text-xs leading-relaxed">
              Say something — you're watching with others.
            </div>
          </div>
        </div>
        <ul
          id={@list_id}
          phx-update="stream"
          phx-hook="ChatAutoScroll"
          data-scroll={"##{@scroll_id}"}
          data-host={"##{@host_id}"}
          class="divide-y divide-white/5 text-sm"
        >
          <%= for {dom_id, msg} <- @streams.messages do %>
            <li id={dom_id} class="px-4 py-3">
              <div class="flex items-center justify-between">
                <span class="font-medium text-zinc-300 text-sm">
                  {(msg.user && "@" <> msg.user.username) || "Member"}
                </span>
                <span class="text-xs text-zinc-400">
                  {TimesinkWeb.Cinema.TheaterLive.chat_time(msg.inserted_at)}
                </span>
              </div>
              <p class="text-gray-100 text-sm mt-1">{msg.content}</p>
            </li>
          <% end %>
        </ul>
        <%= if map_size(@typing_users) > 0 do %>
          <div class="px-4 py-2 text-xs text-zinc-400 border-t border-white/5">
            {TimesinkWeb.Cinema.TheaterLive.typing_line(@typing_users, @presence)}
          </div>
        <% end %>
      </div>

      <div class={[
        "overflow-y-auto overscroll-contain p-3",
        @body_class,
        @chat_tab != :audience && "hidden"
      ]}>
        <%= if map_size(@presence) > 0 do %>
          <ul class="space-y-2">
            <%= for {_user_id, %{metas: [meta | _]}} <- @presence do %>
              <li class="flex items-center justify-between rounded-lg border border-white/10 px-3 py-2 bg-zinc-900/60 hover:bg-zinc-800/60 transition">
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
                    <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                  </span>
                  online
                </span>
              </li>
            <% end %>
          </ul>
        <% else %>
          <div class="text-center text-zinc-400 text-sm py-8">No one is currently watching</div>
        <% end %>
      </div>

      <form phx-submit="chat:send" class="p-3 border-t border-white/8 shrink-0">
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
          <button class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm bg-white/6 text-gray-200 hover:bg-white/10 transition">
            Send
          </button>
        </div>
      </form>
    </div>
    """
  end

  # ── Notes ──────────────────────────────────────────────────

  attr :notes, :list, required: true
  attr :total_notes_count, :integer, required: true
  attr :newly_surfaced_ids, :any, required: true
  attr :just_posted_note_id, :any, required: true
  attr :new_notes_count, :integer, required: true
  attr :note_status_message, :any, required: true
  attr :note_moment_message, :any, required: true
  attr :note_form_open, :boolean, required: true
  attr :note_body, :string, required: true
  attr :note_anchor_offset, :any, required: true
  attr :film, :any, required: true
  attr :list_id, :string, required: true
  attr :scroll_id, :string, required: true
  attr :body_class, :string, default: "max-h-[40vh]"

  def notes_panel(assigns) do
    ~H"""
    <div class="flex flex-col relative">
      <%= if @note_moment_message do %>
        <div class="mx-4 mt-3 rounded-lg border border-blue-500/20 bg-blue-500/8 px-3 py-2 text-xs text-blue-300/80 flex items-center gap-2">
          <.icon name="hero-bookmark" class="w-3.5 h-3.5 shrink-0 text-blue-400/60" />
          <span class="text-zinc-400">Moment pinned at</span>
          <span class="text-blue-300/90 font-medium">{@note_moment_message}</span>
        </div>
      <% end %>

      <%= if @note_status_message do %>
        <div class="mx-4 mt-3 rounded-lg border border-emerald-500/20 bg-emerald-500/8 px-3 py-2 text-xs text-emerald-300/80 flex items-center gap-2">
          <.icon name="hero-check-circle" class="w-3.5 h-3.5 shrink-0 text-emerald-400/60" />
          <span class="text-zinc-400">Note pinned at</span>
          <span class="text-emerald-300/90 font-medium">{@note_status_message}</span>
        </div>
      <% end %>

      <div
        id={@scroll_id}
        phx-hook="NotesNewBanner"
        class={[@body_class, "overflow-y-auto overscroll-contain relative"]}
      >
        <%= if Enum.empty?(@notes) do %>
          <div class="flex flex-col items-center justify-center min-h-40 gap-3 text-center px-6 py-8">
            <.icon name="hero-document" class="w-5 h-5 text-zinc-700" />
            <%= if @total_notes_count > 0 do %>
              <div class="space-y-1">
                <p class="text-sm text-zinc-400 font-medium">
                  {@total_notes_count} notes in this screening
                </p>
                <p class="text-xs text-zinc-600 leading-relaxed">
                  They are presented in order as the film plays.
                </p>
              </div>
            <% else %>
              <div class="space-y-1">
                <p class="text-sm text-zinc-400 font-medium">No notes yet</p>
                <p class="text-xs text-zinc-600 leading-relaxed">Pin a moment to leave one.</p>
              </div>
            <% end %>
          </div>
        <% else %>
          <ul
            id={@list_id}
            phx-hook="NotesAutoScroll"
            data-scroll={"##{@scroll_id}"}
            class="divide-y divide-white/5"
          >
            <%= for note <- @notes do %>
              <% is_new = MapSet.member?(@newly_surfaced_ids, note.id) %>
              <% is_just_posted = @just_posted_note_id == note.id %>
              <% thumb = mux_thumbnail_url(Film.get_mux_playback_id(@film.video), note.offset_seconds) %>
              <li class={["px-3 py-1.5", is_new && "note-surface"]}>
                <div class={[
                  "flex items-start gap-3 px-3 py-3 rounded-xl border-l-2 border border-white/6 transition-all duration-700",
                  is_new && "border-l-white/40 bg-white/5",
                  is_just_posted && "border-l-white/25 bg-white/4",
                  !is_new && !is_just_posted && "border-l-zinc-600/40 bg-white/[0.02]"
                ]}>
                  <%= if thumb do %>
                    <img
                      src={thumb}
                      alt=""
                      class={[
                        "w-16 h-9 rounded-md object-cover shrink-0 transition-all duration-700",
                        is_new && "opacity-80 scale-[1.02]",
                        !is_new && "opacity-60"
                      ]}
                      loading="lazy"
                    />
                  <% end %>
                  <div class="min-w-0 flex-1">
                    <div class="flex items-center justify-between">
                      <span class="text-zinc-100 text-sm truncate">
                        {(note.user && "@" <> note.user.username) || "Member"}
                      </span>
                      <span class="text-xs text-zinc-400 shrink-0">
                        {TimesinkWeb.Cinema.TheaterLive.format_offset(note.offset_seconds)}
                      </span>
                    </div>
                    <p class="mt-0.5 font-light text-zinc-100/60 text-sm whitespace-pre-line leading-snug">
                      {note.body}
                    </p>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
        <div id={"#{@scroll_id}-incoming"} phx-hook="NotesIncoming" class="hidden"></div>
      </div>

      <%= if @note_form_open do %>
        <% form_thumb = mux_thumbnail_url(Film.get_mux_playback_id(@film.video), @note_anchor_offset) %>
        <div class="border-t border-white/8 shrink-0">
          <div class="px-3 pt-3 flex items-start gap-3">
            <%= if form_thumb do %>
              <div class="relative w-16 h-9 shrink-0">
                <div class="absolute inset-0 rounded-md bg-zinc-800 animate-pulse"></div>
                <img
                  src={form_thumb}
                  alt=""
                  class="relative w-16 h-9 rounded-md object-cover opacity-60"
                  onload="this.previousElementSibling.style.display='none'"
                />
              </div>
            <% else %>
              <div class="w-16 h-9 rounded-md bg-white/6 shrink-0 flex items-center justify-center">
                <.icon name="hero-map-pin" class="w-3.5 h-3.5 text-zinc-600" />
              </div>
            <% end %>
            <span class="flex items-center gap-1 text-xs text-zinc-500 pt-1">
              <.icon name="hero-map-pin" class="w-3 h-3 shrink-0" />
              {TimesinkWeb.Cinema.TheaterLive.format_offset(@note_anchor_offset)}
            </span>
          </div>
          <form phx-submit="note:save" phx-change="note:change" class="p-3 space-y-2">
            <textarea
              name="note[body]"
              rows="2"
              phx-mounted={JS.focus()}
              phx-debounce="100"
              class="w-full bg-white/4 border border-white/10 rounded-lg px-3 py-2 text-sm text-gray-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-white/20 resize-none"
              placeholder="Note this moment…"
            ><%= @note_body %></textarea>
            <div class="flex items-center justify-between">
              <button
                type="button"
                phx-click="cancel_note"
                class="cursor-pointer text-xs text-zinc-500 hover:text-zinc-300 transition"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="cursor-pointer inline-flex items-center justify-center rounded-lg px-3 py-1.5 text-sm bg-white/6 text-gray-200 hover:bg-white/10 transition"
              >
                Post
              </button>
            </div>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  # ── Director ───────────────────────────────────────────────

  attr :all_commentary, :list, required: true
  attr :surfaced_ids, :any, required: true
  attr :newly_surfaced_director_ids, :any, required: true
  attr :about_to_surface_ids, :any, required: true
  attr :next_director_seconds_away, :integer, default: nil
  attr :total_count, :integer, required: true
  attr :film, :any, required: true
  attr :phase, :atom, required: true
  attr :scroll_id, :string, required: true
  attr :body_class, :string, default: "max-h-[40vh]"

  def director_panel(assigns) do
    ~H"""
    <div class={[@body_class, "overflow-y-auto overscroll-contain"]}>
      <%= if @total_count == 0 do %>
        <%!-- No commentary at all --%>
        <div class="flex flex-col items-center justify-center min-h-40 gap-3 text-center px-6 py-8">
          <.icon name="hero-megaphone" class="w-5 h-5 text-zinc-700" />
          <div>
            <p class="text-sm text-zinc-400 font-medium">No commentary</p>
            <p class="text-xs text-zinc-600 mt-1 leading-relaxed">
              The director hasn't left any commentary for this film.
            </p>
          </div>
        </div>
      <% else %>
        <%= if @phase != :playing do %>
          <%!-- Film hasn't started — tease that commentary exists but don't reveal cards --%>
          <div class="flex flex-col items-center justify-center min-h-40 gap-3 text-center px-6 py-8">
            <.icon name="hero-megaphone" class="w-5 h-5 text-amber-700/50" />
            <div>
              <p class="text-sm text-amber-400/70 font-medium">Commentary ahead</p>
              <p class="text-xs text-zinc-600 mt-1 leading-relaxed">
                The director has left commentary that will unlock as the film plays.
              </p>
            </div>
          </div>
        <% else %>
          <%!-- Film is playing — show "next up" hint at top if something is about to surface --%>
          <%= if not MapSet.equal?(@about_to_surface_ids, MapSet.new()) do %>
            <% countdown_label = cond do
                @next_director_seconds_away != nil and @next_director_seconds_away < 10 ->
                  "New commentary is moments away..."
                @next_director_seconds_away != nil ->
                  rounded = round(@next_director_seconds_away / 5) * 5
                  "New commentary is on its way · ~#{rounded}s"
                true -> "New commentary is on its way..."
              end
            %>
            <div class="mx-4 mt-3 mb-1 px-3 py-2 rounded-lg border border-amber-500/15 bg-amber-500/5 flex items-center gap-2">
              <span class="text-[11px] text-amber-600/80 tracking-wide">{countdown_label}</span>
            </div>
          <% end %>
          <ul class="divide-y divide-white/5">
            <%= for entry <- @all_commentary do %>
              <% is_surfaced = MapSet.member?(@surfaced_ids, entry.id) %>
              <% is_new = MapSet.member?(@newly_surfaced_director_ids, entry.id) %>
              <% is_next = MapSet.member?(@about_to_surface_ids, entry.id) %>
              <% thumb = mux_thumbnail_url(Film.get_mux_playback_id(@film.video), entry.offset_seconds) %>
              <% director_name =
                entry.user && entry.user.creative &&
                  Timesink.Cinema.Creative.full_name(entry.user.creative) %>
              <li class="px-4 py-2">
                <div class={[
                  "flex items-start gap-3 px-4 py-3 rounded-xl border-l-2 border border-white/6 transition-all duration-700",
                  is_new && "border-l-amber-400 bg-amber-900/20",
                  is_surfaced && not is_new && "border-l-amber-600/40 bg-amber-950/10",
                  not is_surfaced && is_next && "border-l-amber-700/40 bg-amber-950/5 animate-pulse",
                  not is_surfaced && not is_next && "border-l-zinc-800/40 bg-white/1"
                ]}>
                  <%= if thumb do %>
                    <img
                      src={thumb}
                      alt=""
                      class={[
                        "w-16 h-9 rounded-md object-cover shrink-0 transition-all duration-700",
                        is_surfaced && "opacity-60",
                        not is_surfaced && "opacity-15 blur-sm"
                      ]}
                      loading="lazy"
                    />
                  <% end %>
                  <div class={[
                    "min-w-0 flex-1 transition-all duration-700",
                    not is_surfaced && "blur-sm select-none"
                  ]}>
                    <div class="flex items-center justify-between mb-1">
                      <span class="inline-flex items-center gap-1 text-[10px] font-medium text-amber-500/80 uppercase tracking-wider">
                        <.icon name="hero-megaphone" class="w-3 h-3" />
                        {if director_name, do: director_name, else: "Director"}
                      </span>
                      <span class="text-xs text-zinc-400 font-mono shrink-0">
                        {format_offset(entry.offset_seconds)}
                      </span>
                    </div>
                    <p class="mt-0.5 font-light text-zinc-100/60 text-sm whitespace-pre-line leading-snug">
                      {entry.body}
                    </p>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp format_offset(nil), do: "00:00:00"

  defp format_offset(seconds) do
    h = div(seconds, 3600)
    m = seconds |> rem(3600) |> div(60)
    s = rem(seconds, 60)
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s]) |> to_string()
  end

  # ── Private ────────────────────────────────────────────────

  defp mux_thumbnail_url(nil, _), do: nil

  defp mux_thumbnail_url(playback_id, offset) when is_binary(playback_id) do
    seconds = offset |> trunc() |> max(0)

    "https://image.mux.com/#{playback_id}/thumbnail.jpg?time=#{seconds}&width=320&fit_mode=preserve"
  end
end
