defmodule TimesinkWeb.Cinema.DirectorCommentaryLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.{Film, DirectorCommentary}
  alias Timesink.Cinema.Note
  alias Timesink.Cinema.Film.Note, as: FilmNote
  import TimesinkWeb.Cinema.FilmLive, only: [title_slug: 1]

  on_mount {TimesinkWeb.Auth, :ensure_authenticated}

  @impl true
  def mount(%{"title" => title_param, "director" => director_param}, _session, socket) do
    film = find_film(title_param, director_param)

    case film do
      nil ->
        {:ok, assign(socket, not_found: true)}

      %Film{} ->
        user = socket.assigns.current_user

        if DirectorCommentary.director_of_film?(user, film.id) do
          playback_id = Film.get_mux_playback_id(film.video)
          commentary = FilmNote.list_commentary(film.id)

          {:ok,
           assign(socket,
             not_found: false,
             film: film,
             playback_id: playback_id,
             commentary: commentary,
             editing_id: nil,
             edit_body: "",
             open_menu_id: nil,
             confirm_delete_id: nil,
             add_form_open: false,
             add_body: "",
             char_count: 0,
             current_offset: 0,
             page_title: "#{film.title} — Director's Commentary"
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "You don't have access to this film's commentary.")
           |> assign(not_found: true)}
        end
    end
  end

  @impl true
  def render(%{not_found: true} = assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-16">
      <div class="max-w-3xl mx-auto text-center">
        <h1 class="text-xl font-semibold text-mystery-white">Film not found</h1>
        <.link navigate={~p"/"} class="inline-block mt-6 text-neon-blue-lightest hover:opacity-80">
          Back to home
        </.link>
      </div>
    </section>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Delete confirmation modal -->
    <%= if @confirm_delete_id do %>
      <div
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm"
        phx-click="cancel_delete"
      >
        <div
          class="relative mx-4 w-full max-w-sm rounded-2xl bg-zinc-900 ring-1 ring-zinc-700 shadow-2xl p-6"
          phx-click-away="cancel_delete"
        >
          <div class="flex items-start gap-4 mb-5">
            <div class="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-red-500/15 ring-1 ring-red-500/30">
              <.icon name="hero-trash" class="w-5 h-5 text-red-400" />
            </div>
            <div>
              <h3 class="text-sm font-semibold text-white leading-snug">Delete commentary?</h3>
              <p class="mt-1 text-xs text-zinc-400 leading-relaxed">
                This will permanently remove the comment entry. It cannot be undone.
              </p>
            </div>
          </div>
          <div class="flex justify-end gap-2">
            <button
              phx-click="cancel_delete"
              class="cursor-pointer px-4 py-2 text-xs font-medium rounded-lg text-zinc-300 bg-zinc-800 hover:bg-zinc-700 transition"
            >
              Cancel
            </button>
            <button
              phx-click="confirm_delete"
              class="cursor-pointer px-4 py-2 text-xs font-medium rounded-lg text-white bg-red-600 hover:bg-red-500 transition"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <div class="max-w-7xl mx-auto px-4 md:px-6 mt-16 text-gray-100">
      <!-- Header -->
      <div class="border-b border-white/10 pb-4 mb-8">
        <p class="text-xs uppercase tracking-widest text-zinc-500 mb-1">Director's Commentary</p>
        <h1 class="text-lg font-bold font-gangster">{@film.title}</h1>
      </div>
      
    <!-- Main layout: player left, commentary panel right -->
      <div class="flex flex-col md:flex-row md:gap-6 md:items-start">
        <!-- Player -->
        <div class="min-w-0 md:flex-1">
          <%= if @playback_id do %>
            <div class="relative mx-auto w-full max-w-[920px]">
              <mux-player
                id="director-player"
                playback-id={@playback_id}
                stream-type="on-demand"
                metadata-video-title={@film.title}
                metadata-video-id={@film.id}
                class="w-full aspect-video rounded overflow-hidden"
                phx-hook="DirectorPlayer"
              >
              </mux-player>
            </div>
          <% else %>
            <div class="aspect-video w-full rounded bg-zinc-900 flex items-center justify-center">
              <p class="text-zinc-500 text-sm">No video available for this film.</p>
            </div>
          <% end %>
          
    <!-- Add commentary button (shown below player) -->
          <%= if @playback_id do %>
            <div class="mt-4 flex justify-end">
              <button
                phx-click="open_add_form"
                class="cursor-pointer inline-flex items-center gap-2 rounded-lg bg-amber-600/20 text-amber-300 ring-1 ring-amber-600/40 px-4 py-2 text-sm font-medium hover:bg-amber-600/30 transition"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Add Commentary
              </button>
            </div>
          <% end %>
          
    <!-- Add form (appears below button when open) -->
          <%= if @add_form_open do %>
            <div class="mt-3 rounded-xl bg-zinc-900 ring-1 ring-zinc-700 p-4">
              <% thumb = mux_thumbnail_url(@playback_id, @current_offset) %>
              <div class="flex items-center gap-3 mb-3">
                <%= if thumb do %>
                  <img
                    src={thumb}
                    alt=""
                    class="w-16 h-9 rounded-md object-cover opacity-70 shrink-0"
                  />
                <% end %>
                <span class="flex items-center gap-1 text-xs text-zinc-500">
                  <.icon name="hero-map-pin" class="w-3 h-3 shrink-0" />
                  {format_offset(@current_offset)}
                </span>
              </div>
              <form phx-change="add_body_change" phx-submit="save_commentary">
                <textarea
                  id="add-commentary-input"
                  phx-hook="DirectorCommentaryInput"
                  name="body"
                  rows="3"
                  placeholder="What would you like to say about this moment?"
                  class="w-full rounded bg-zinc-800 text-sm text-zinc-100 px-3 py-2 resize-none focus:outline-none focus:ring-1 focus:ring-amber-500/50 placeholder-zinc-600"
                >{@add_body}</textarea>
                <div class="flex items-center justify-between mt-2">
                  <span class={[
                    "text-xs",
                    if(@char_count >= 450, do: "text-amber-400", else: "text-zinc-600")
                  ]}>
                    {@char_count}/500
                  </span>
                  <div class="flex gap-2">
                    <button
                      type="button"
                      phx-click="cancel_add"
                      class="cursor-pointer px-3 py-1.5 text-sm text-zinc-400 hover:text-zinc-200 transition"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={@add_body == "" or String.length(@add_body) < 3}
                      class={[
                        "cursor-pointer px-4 py-1.5 rounded-lg text-sm font-medium transition",
                        if(@add_body != "" and String.length(@add_body) >= 3,
                          do: "bg-amber-600 text-white hover:bg-amber-500",
                          else: "bg-zinc-700 text-zinc-500 cursor-not-allowed"
                        )
                      ]}
                    >
                      Save
                    </button>
                  </div>
                </div>
              </form>
            </div>
          <% end %>
        </div>
        
    <!-- Commentary panel -->
        <div class="mt-6 md:mt-0 md:w-80 lg:w-96 shrink-0">
          <div class="rounded-xl bg-zinc-900 ring-1 ring-zinc-800 overflow-hidden">
            <div class="px-4 py-3 border-b border-zinc-800">
              <h2 class="text-xs font-semibold uppercase tracking-widest text-zinc-400">
                Commentary
                <%= if length(@commentary) > 0 do %>
                  <span class="ml-1 text-zinc-600 font-normal normal-case tracking-normal">
                    · {length(@commentary)} {if length(@commentary) == 1, do: "entry", else: "entries"}
                  </span>
                <% end %>
              </h2>
            </div>

            <%= if @commentary == [] do %>
              <div class="px-4 py-8 text-center">
                <p class="text-sm text-zinc-500">No commentary yet.</p>
                <p class="text-xs text-zinc-600 mt-1">
                  Pause the film and click "Add Commentary" to begin.
                </p>
              </div>
            <% else %>
              <ul id="commentary-list" class="divide-y divide-zinc-800 max-h-[600px] overflow-y-auto">
                <li :for={entry <- @commentary} id={"commentary-#{entry.id}"} class="px-4 py-3">
                  <div class="flex items-start justify-between gap-2">
                    <!-- Left: timestamp + body/edit form -->
                    <div class="min-w-0 flex-1">
                      <button
                        phx-click="seek_to"
                        phx-value-offset={entry.offset_seconds}
                        class="cursor-pointer flex items-center gap-1.5 text-xs text-amber-400 hover:text-amber-300 transition mb-1.5 font-mono"
                      >
                        <.icon name="hero-play-circle" class="w-3.5 h-3.5" />
                        {format_offset(entry.offset_seconds)}
                      </button>

                      <%= if @editing_id == entry.id do %>
                        <form phx-change="edit_body_change" phx-submit="save_edit">
                          <input type="hidden" name="_id" value={entry.id} />
                          <textarea
                            id={"edit-input-#{entry.id}"}
                            phx-hook="DirectorCommentaryInput"
                            name="body"
                            rows="3"
                            class="w-full rounded bg-zinc-800 text-sm text-zinc-100 px-3 py-2 resize-none focus:outline-none focus:ring-1 focus:ring-amber-500/50"
                          >{@edit_body}</textarea>
                          <div class="flex gap-2 mt-2 justify-end">
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="cursor-pointer px-3 py-1 text-xs text-zinc-400 hover:text-zinc-200 transition"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="cursor-pointer px-3 py-1 rounded text-xs bg-amber-600 text-white hover:bg-amber-500 transition"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <p class="text-sm text-zinc-200 leading-relaxed">{entry.body}</p>
                      <% end %>
                    </div>
                    
    <!-- Right: 3-dot context menu (always visible, hidden during edit) -->
                    <%= if @editing_id != entry.id do %>
                      <div class="relative shrink-0">
                        <button
                          phx-click="toggle_menu"
                          phx-value-id={entry.id}
                          class="cursor-pointer inline-flex items-center justify-center w-7 h-7 rounded-md text-zinc-500 hover:text-zinc-300 hover:bg-white/6 transition"
                          aria-label="Options"
                        >
                          <.icon name="hero-ellipsis-horizontal" class="w-4 h-4" />
                        </button>

                        <%= if @open_menu_id == entry.id do %>
                          <div
                            class="absolute right-0 top-8 z-20 min-w-[120px] rounded-lg border border-zinc-700 bg-zinc-900 shadow-xl py-1"
                            phx-click-away="close_menu"
                          >
                            <button
                              phx-click="edit_commentary"
                              phx-value-id={entry.id}
                              class="cursor-pointer w-full text-left px-3 py-2 text-xs text-zinc-300 hover:bg-white/6 hover:text-white transition flex items-center gap-2"
                            >
                              <.icon name="hero-pencil" class="w-3.5 h-3.5" /> Edit
                            </button>
                            <button
                              phx-click="prompt_delete"
                              phx-value-id={entry.id}
                              class="cursor-pointer w-full text-left px-3 py-2 text-xs text-red-400 hover:bg-red-500/10 hover:text-red-300 transition flex items-center gap-2"
                            >
                              <.icon name="hero-trash" class="w-3.5 h-3.5" /> Delete
                            </button>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </li>
              </ul>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Events ───────────────────────────────────────────────────

  @impl true
  def handle_event("open_add_form", _params, socket) do
    {:noreply,
     socket
     |> push_event("director:pause", %{})
     |> assign(add_form_open: true, add_body: "", char_count: 0)}
  end

  def handle_event("cancel_add", _params, socket) do
    {:noreply, assign(socket, add_form_open: false, add_body: "", char_count: 0)}
  end

  def handle_event("add_body_change", %{"body" => body}, socket) do
    {:noreply, assign(socket, add_body: body, char_count: String.length(body))}
  end

  def handle_event("save_commentary", _params, %{assigns: %{add_body: ""}} = socket) do
    {:noreply, socket}
  end

  def handle_event("save_commentary", _params, %{assigns: assigns} = socket) do
    user = assigns.current_user
    film = assigns.film
    offset = assigns.current_offset || 0

    case FilmNote.create_commentary(user, film.id, %{
           body: String.trim(assigns.add_body),
           offset_seconds: offset
         }) do
      {:ok, _note} ->
        commentary = FilmNote.list_commentary(socket.assigns.film.id)

        {:noreply,
         socket
         |> put_flash(:success, "Comment added.")
         |> assign(
           commentary: commentary,
           add_form_open: false,
           add_body: "",
           char_count: 0
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not save commentary. Please try again.")}
    end
  end

  def handle_event("edit_commentary", %{"id" => id}, socket) do
    entry = Enum.find(socket.assigns.commentary, &(&1.id == id))

    if entry do
      {:noreply, assign(socket, editing_id: id, edit_body: entry.body, open_menu_id: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_id: nil, edit_body: "")}
  end

  def handle_event("edit_body_change", %{"body" => body}, socket) do
    {:noreply, assign(socket, edit_body: body)}
  end

  def handle_event("save_edit", %{"_id" => id}, socket) do
    entry = Enum.find(socket.assigns.commentary, &(&1.id == id))

    case entry && Note.update(entry, %{body: String.trim(socket.assigns.edit_body)}) do
      {:ok, _updated} ->
        commentary = FilmNote.list_commentary(socket.assigns.film.id)

        {:noreply,
         socket
         |> put_flash(:success, "Comment updated.")
         |> assign(commentary: commentary, editing_id: nil, edit_body: "")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update commentary.")}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("close_menu", _params, socket) do
    {:noreply, assign(socket, open_menu_id: nil)}
  end

  def handle_event("toggle_menu", %{"id" => id}, socket) do
    open = if socket.assigns.open_menu_id == id, do: nil, else: id
    {:noreply, assign(socket, open_menu_id: open)}
  end

  def handle_event("prompt_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete_id: id, open_menu_id: nil)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete_id: nil)}
  end

  def handle_event("confirm_delete", _params, socket) do
    id = socket.assigns.confirm_delete_id
    entry = Enum.find(socket.assigns.commentary, &(&1.id == id))

    case entry && Note.delete(entry) do
      {:ok, _} ->
        commentary = FilmNote.list_commentary(socket.assigns.film.id)

        {:noreply,
         socket
         |> put_flash(:success, "Comment removed.")
         |> assign(commentary: commentary, confirm_delete_id: nil)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not delete comment.")
         |> assign(confirm_delete_id: nil)}

      nil ->
        {:noreply, assign(socket, confirm_delete_id: nil)}
    end
  end

  def handle_event("delete_commentary", %{"id" => id}, socket) do
    entry = Enum.find(socket.assigns.commentary, &(&1.id == id))

    case entry && Note.delete(entry) do
      {:ok, _} ->
        commentary = FilmNote.list_commentary(socket.assigns.film.id)
        {:noreply, assign(socket, commentary: commentary)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete comment.")}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("seek_to", %{"offset" => offset}, socket) do
    offset = String.to_integer(offset)
    {:noreply, push_event(socket, "director:seek", %{offset: offset})}
  end

  def handle_event("player:timeupdate", %{"offset" => offset}, socket) do
    {:noreply, assign(socket, current_offset: trunc(offset))}
  end

  # ── Helpers ──────────────────────────────────────────────────

  defp find_film(title_param, director_param) do
    alias Timesink.Cinema.Film
    alias Timesink.Repo

    Film
    |> Repo.all()
    |> Enum.find(fn f -> title_slug(f.title) == title_param end)
    |> case do
      nil ->
        nil

      f ->
        preloaded =
          Repo.preload(f, [
            {:video, [:blob]},
            :genres,
            directors: [creative: :user]
          ])

        dir_slug =
          case preloaded.directors do
            [] ->
              "unknown"

            directors ->
              directors
              |> Enum.max_by(&String.downcase(&1.creative.last_name || ""))
              |> then(&title_slug(&1.creative.last_name))
          end

        if dir_slug == director_param, do: preloaded, else: nil
    end
  end

  defp mux_thumbnail_url(nil, _), do: nil

  defp mux_thumbnail_url(playback_id, offset) when is_binary(playback_id) do
    seconds = (offset || 0) |> trunc() |> max(0)

    "https://image.mux.com/#{playback_id}/thumbnail.jpg?time=#{seconds}&width=320&fit_mode=preserve"
  end

  defp format_offset(nil), do: "00:00:00"

  defp format_offset(seconds) do
    h = div(seconds, 3600)
    m = seconds |> rem(3600) |> div(60)
    s = rem(seconds, 60)
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s]) |> to_string()
  end
end
