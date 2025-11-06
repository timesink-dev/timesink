defmodule TimesinkWeb.Cinema.NowPlayingLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics}
  alias Timesink.{Repo, UserCache}
  alias Timesink.Account.{User, Profile}
  import TimesinkWeb.Components.NoShowcase

  def mount(params, _session, socket) do
    current_user = socket.assigns[:current_user]

    # Common welcome modal setup - applies regardless of showcase state
    show_welcome_modal = params["welcome"] == "1" and needs_avatar?(current_user)

    socket =
      socket
      |> assign(
        show_welcome_modal: show_welcome_modal,
        welcome_bio: "",
        welcome_avatar_error: nil
      )
      |> allow_upload(:welcome_avatar,
        accept: ~w(.jpg .jpeg .png .webp .heic),
        max_entries: 1,
        max_file_size: 8_000_000,
        auto_upload: false
      )

    # Showcase-specific logic
    socket =
      with showcase when not is_nil(showcase) <- Cinema.get_active_showcase_with_exhibitions() do
        exhibitions =
          (showcase.exhibitions || [])
          |> Cinema.preload_exhibitions()
          |> Enum.sort_by(& &1.theater.name, :asc)

        playback_states = Timesink.Cinema.compute_initial_playback_states(exhibitions, showcase)

        assign(socket,
          showcase: showcase,
          exhibitions: exhibitions,
          playback_states: playback_states,
          presence: %{},
          upcoming_showcase: nil,
          no_showcase: false
        )
      else
        nil ->
          case Cinema.get_upcoming_showcase() do
            %{} = upcoming ->
              assign(socket,
                showcase: nil,
                exhibitions: [],
                playback_states: %{},
                presence: %{},
                upcoming_showcase: upcoming,
                no_showcase: false
              )

            nil ->
              assign(socket,
                showcase: nil,
                exhibitions: [],
                playback_states: %{},
                presence: %{},
                upcoming_showcase: nil,
                no_showcase: true
              )
          end
      end

    if connected?(socket), do: send(self(), :connected)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="now-playing">
      <%= cond do %>
        <% @showcase -> %>
          <.live_component
            id="theater-showcase"
            module={TheaterShowcaseComponent}
            showcase={@showcase}
            exhibitions={@exhibitions}
            presence={@presence}
            playback_states={@playback_states}
          />
        <% @upcoming_showcase -> %>
          <div class="text-center text-white my-32 px-6 max-w-xl mx-auto h-[100vh] flex flex-col items-center justify-center">
            <.icon name="hero-clock" class="h-16 w-16 mb-6 text-neon-blue-lightest" />
            <h1 class="text-4xl font-bold mb-4">Upcoming Showcase</h1>
            <h2 class="text-2xl font-semibold text-neon-blue-lightest mb-2">
              {@upcoming_showcase.title}
            </h2>
            <p class="text-gray-400 mb-4">
              {@upcoming_showcase.description}
            </p>
            <p class="text-gray-500 text-sm">
              Starts
              <span class="font-medium">
                {Calendar.strftime(@upcoming_showcase.start_at, "%A, %B %d at %H:%M")}
              </span>
            </p>
          </div>
        <% @no_showcase -> %>
          <.no_showcase class="mt-16" />
      <% end %>
      <%= if @show_welcome_modal do %>
        <.modal id="welcome-modal" show={@show_welcome_modal} on_cancel={JS.push("dismiss_welcome")}>
          <div class="mx-auto w-full max-w-lg md:max-w-xl lg:max-w-xl px-6 py-4 md:px-10 md:py-6">
            <div class="text-center">
              <div class="mx-auto mb-4 h-1 w-16 rounded-full bg-gradient-to-r from-neon-blue-lightest/70 to-transparent">
              </div>
              <h2
                id="welcome-title"
                class="text-2xl md:text-3xl font-semibold tracking-tight text-mystery-white pb-1"
              >
                Welcome to TimeSink
              </h2>
              <p class="mt-3 text-sm md:text-base text-zinc-400 leading-relaxed">
                Before getting started in the theaters, it helps to add a profile image and a short bio to make you even more interesting.
              </p>
            </div>

            <.simple_form
              for={%{}}
              phx-submit="save_welcome_profile"
              phx-change="welcome_upload_change"
              class="mt-6 md:mt-8 space-y-6 md:space-y-8 w-full mx-auto max-w-sm md:max-w-lg
         phx-submit-loading:opacity-70 phx-submit-loading:pointer-events-none"
            >
              <!-- Avatar row: stacked on mobile, side-by-side on md+ -->
              <div class="flex flex-col md:flex-row items-center md:items-center gap-4">
                <div class="relative">
                  <!-- Avatar circle scales up slightly on desktop -->
                  <div class="grid h-16 w-16 md:h-16 md:w-16 lg:h-20 lg:w-20 place-items-center overflow-hidden rounded-full bg-zinc-900
                      ring-1 ring-zinc-700 transition hover:ring-neon-blue-lightest/50 focus-within:ring-neon-blue-lightest/70">
                    <%= if @uploads.welcome_avatar.entries != [] do %>
                      <%= for entry <- @uploads.welcome_avatar.entries do %>
                        <.live_img_preview entry={entry} class="h-full w-full object-cover" />
                      <% end %>
                    <% else %>
                      <span class="inline-flex h-16 w-16 md:h-20 md:w-20 items-center justify-center rounded-full bg-zinc-700 text-xl md:text-2xl font-semibold text-mystery-white ring-2 ring-zinc-700">
                        {initials(@current_user)}
                      </span>
                    <% end %>
                  </div>
                  
    <!-- Clickable overlay (keeps input interactive without layout shift) -->
                  <.live_file_input
                    upload={@uploads.welcome_avatar}
                    class="absolute inset-0 opacity-0 cursor-pointer"
                  />
                </div>

                <p class="text-xs text-zinc-500 text-center md:text-left leading-snug md:max-w-[260px]">
                  JPG, PNG, WEBP — up to 8&nbsp;MB.
                </p>
              </div>

              <p
                :if={@welcome_avatar_error}
                class="text-xs text-red-400 -mt-2 md:-mt-3 text-center md:text-left"
              >
                {@welcome_avatar_error}
              </p>
              
    <!-- Bio -->
              <div>
                <label class="mb-2 block text-sm font-medium text-zinc-300 text-left">Bio</label>
                <textarea
                  name="bio"
                  placeholder="Tell the world about yourself in one line or less — or more if you'd like.."
                  phx-debounce="300"
                  phx-change="welcome_bio_change"
                  class="min-h-[100px] w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                >{@welcome_bio}</textarea>
                <p class="mt-2 text-xs text-zinc-500 text-left">
                  Don't worry you can edit these details anytime in your profile settings.
                </p>
              </div>
              
    <!-- Actions: full-width on mobile, right-aligned on md+ -->
              <:actions>
                <div class="flex flex-col md:flex-row justify-end gap-3 pt-1 md:pt-2">
                  <.button
                    type="button"
                    color="secondary"
                    class="w-full md:w-auto"
                    phx-click="dismiss_welcome"
                  >
                    Skip for now
                  </.button>

                  <.button
                    type="submit"
                    color="primary"
                    classes={[
                      "w-full md:w-auto phx-submit-loading:cursor-wait phx-submit-loading:opacity-80",
                      (String.trim(@welcome_bio || "") == "" and @uploads.welcome_avatar.entries == []) &&
                        "opacity-50 cursor-not-allowed"
                    ]}
                    disabled={
                      String.trim(@welcome_bio || "") == "" and @uploads.welcome_avatar.entries == []
                    }
                  >
                    <span class="inline-flex items-center gap-2 phx-submit-loading:hidden">
                      Save
                    </span>
                    <span class="hidden phx-submit-loading:inline-flex items-center gap-2">
                      <svg
                        class="w-4 h-4 animate-spin"
                        viewBox="0 0 24 24"
                        fill="none"
                        aria-hidden="true"
                      >
                        <circle
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="3"
                          opacity=".25"
                        />
                        <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" stroke-width="3" />
                      </svg>
                      Saving…
                    </span>
                  </.button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end

  def handle_info(:connected, %{assigns: %{showcase: %{exhibitions: exhibitions}}} = socket)
      when is_list(exhibitions) do
    presence =
      exhibitions
      |> Enum.map(fn ex ->
        presence_topic = PubSubTopics.presence_topic(ex.theater_id)
        Phoenix.PubSub.subscribe(Timesink.PubSub, presence_topic)
        {presence_topic, Presence.list(presence_topic)}
      end)
      |> Enum.into(%{})

    {:noreply, assign(socket, :presence, presence)}
  end

  def handle_info(:connected, socket) do
    # No active showcase, nothing to subscribe to
    {:noreply, socket}
  end

  def handle_info(
        %{
          event: "phase_change",
          playback_state:
            %{
              theater_id: theater_id
            } = playback_state
        },
        socket
      ) do
    updated_states =
      Map.update(socket.assigns[:playback_states] || %{}, theater_id, playback_state, fn _ ->
        playback_state
      end)

    {:noreply, assign(socket, :playback_states, updated_states)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    {:noreply, update(socket, :presence, &Map.put(&1, topic, updated))}
  end

  # Bio input
  def handle_event("welcome_bio_change", %{"bio" => bio}, socket) do
    {:noreply, assign(socket, welcome_bio: to_string(bio))}
  end

  def handle_event("welcome_upload_change", _params, socket) do
    # This causes LV to track the selected file and populate @uploads...entries
    {:noreply, socket}
  end

  # Save button (updates bio; avatar handled separately by upload flow)
  def handle_event("save_welcome_profile", %{"bio" => bio}, socket) do
    user = load_user!(socket.assigns.current_user.id)
    profile = user.profile || raise "User has no profile"

    # attach image only if the user picked one; get URL from the returned attachment
    {avatar_url, _attached?} =
      consume_uploaded_entries(socket, :welcome_avatar, fn %{path: path}, entry ->
        plug = %Plug.Upload{
          path: path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        case Timesink.Account.Profile.attach_avatar(profile, plug, user_id: user.id) do
          {:ok, att} -> {:ok, {:url, Timesink.Account.Profile.avatar_url(att)}}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)
      |> Enum.reduce({nil, false}, fn
        {:url, url}, _acc -> {url, true}
        {:error, _}, acc -> acc
        _, acc -> acc
      end)

    # update bio
    params = %{"profile" => %{"id" => profile.id, "bio" => to_string(bio)}}

    case Timesink.Account.User.update(user, params) do
      {:ok, updated_user} ->
        # Prefer the URL we just built from the attachment; if none, fall back to current
        final_url = avatar_url || Timesink.Account.Profile.avatar_url(updated_user.profile.avatar)

        UserCache.put(%{
          id: updated_user.id,
          username: updated_user.username,
          first_name: updated_user.first_name,
          last_name: updated_user.last_name,
          email: updated_user.email,
          avatar_url: final_url
        })

        {:noreply,
         socket
         |> assign(show_welcome_modal: false, welcome_bio: "")
         |> assign(current_user: updated_user)
         |> put_flash(:info, "Profile updated — welcome to the show!")}

      {:error, _cs} ->
        {:noreply, put_flash(socket, :error, "Could not save your profile. Please try again.")}
    end
  end

  def handle_event("dismiss_welcome", _, socket) do
    {:noreply, assign(socket, show_welcome_modal: false)}
  end

  # helpers
  defp load_user!(id),
    do:
      Repo.get!(User, id)
      |> Repo.preload(profile: [avatar: [:blob]])

  defp initials(%{first_name: fnm, last_name: lnm}) do
    f = fnm |> to_string() |> String.trim() |> String.first() || ""
    l = lnm |> to_string() |> String.trim() |> String.first() || ""

    case String.upcase(f <> l) do
      "" -> "?"
      s -> s
    end
  end

  defp needs_avatar?(nil), do: true

  defp needs_avatar?(%{avatar_url: url}) do
    # mini-map shape from UserCache
    not (is_binary(url) and url != "")
  end

  defp needs_avatar?(%User{} = u) do
    u = Repo.preload(u, profile: [avatar: [:blob]])

    case u.profile do
      %Profile{avatar: att} when not is_nil(att) ->
        url = Profile.avatar_url(att)
        not (is_binary(url) and url != "")

      _ ->
        true
    end
  end

  defp needs_avatar?(_), do: true
end
