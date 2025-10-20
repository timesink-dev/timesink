defmodule TimesinkWeb.Cinema.NowPlayingLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics}
  alias Timesink.{Repo, UserCache}
  alias Timesink.Account.{User, Profile}

  def mount(params, _session, socket) do
    current_user = socket.assigns[:current_user]

    with showcase when not is_nil(showcase) <- Cinema.get_active_showcase_with_exhibitions() do
      exhibitions =
        (showcase.exhibitions || [])
        |> Cinema.preload_exhibitions()
        |> Enum.sort_by(& &1.theater.name, :asc)

      playback_states = Timesink.Cinema.compute_initial_playback_states(exhibitions, showcase)

      IO.inspect(current_user, label: "current dawg")

      needs_avatar? = true

      show_welcome_modal = params["welcome"] == "1" and needs_avatar?

      socket =
        assign(socket,
          show_welcome_modal: show_welcome_modal,
          welcome_bio: "",
          welcome_avatar_error: nil,
          showcase: showcase,
          exhibitions: exhibitions,
          playback_states: playback_states,
          presence: %{},
          upcoming_showcase: nil,
          no_showcase: false
        )

      socket =
        allow_upload(socket, :welcome_avatar,
          accept: ~w(.jpg .jpeg .png .webp .heic),
          max_entries: 1,
          max_file_size: 8_000_000,
          auto_upload: false
        )

      if connected?(socket), do: send(self(), :connected)
      {:ok, socket}
    else
      nil ->
        case Cinema.get_upcoming_showcase() do
          %{} = upcoming ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: upcoming,
               no_showcase: false
             )}

          nil ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: nil,
               no_showcase: true
             )}
        end
    end
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
          <div class="text-center text-white my-32 px-6 max-w-xl mx-auto h-[100vh] flex flex-col items-center justify-center">
            <.icon name="hero-film" class="h-16 w-16 mb-6 text-neon-blue-lightest" />
            <h1 class="text-4xl font-bold mb-4">No Showcases Available</h1>
            <p class="text-gray-400 mb-8">
              It seems like there are no active or upcoming showcases at the moment.
              Check back later for new screenings!
            </p>
            <p class="text-gray-500 text-sm">
              In the meantime, feel free to explore our
              <a href="/blog" class="text-neon-blue-lightest hover:underline">blog</a>
              for insights and updates.
            </p>
          </div>
      <% end %>
      <%= if @show_welcome_modal do %>
        <.modal id="welcome-modal" show={@show_welcome_modal} on_cancel={JS.push("dismiss_welcome")}>
          <!-- Wrapper: tighter on mobile, roomy on md+ -->
          <div class="mx-auto w-full max-w-lg md:max-w-xl lg:max-w-xl px-6 py-8 md:px-10 md:py-10">
            <!-- Header: centered on all sizes, extra breathing room on md+ -->
            <div class="text-center">
              <div class="mx-auto mb-4 h-1 w-16 rounded-full bg-gradient-to-r from-neon-blue-lightest/70 to-transparent">
              </div>
              <h2
                id="welcome-title"
                class="text-2xl md:text-3xl font-semibold tracking-tight text-mystery-white"
              >
                Welcome to TimeSink
              </h2>
              <p class="mt-3 text-sm md:text-base text-zinc-400 leading-relaxed">
                Before getting started in the theaters, it helps to add a profile image and a short bio so you can be more expressive.
              </p>
            </div>

            <.simple_form
              for={%{}}
              phx-submit="save_welcome_profile"
              phx-change="welcome_upload_change"
              class="mt-6 md:mt-8 space-y-6 md:space-y-8 w-full mx-auto max-w-sm md:max-w-lg"
            >
              <!-- Avatar row: stacked on mobile, side-by-side on md+ -->
              <div class="flex flex-col md:flex-row items-center md:items-start gap-4">
                <div class="relative">
                  <!-- Avatar circle scales up slightly on desktop -->
                  <div class="grid h-16 w-16 md:h-16 md:w-16 lg:h-20 lg:w-20 place-items-center overflow-hidden rounded-full bg-zinc-900
                      ring-1 ring-zinc-700 transition hover:ring-neon-blue-lightest/50 focus-within:ring-neon-blue-lightest/70">
                    <%= if @uploads.welcome_avatar.entries != [] do %>
                      <%= for entry <- @uploads.welcome_avatar.entries do %>
                        <.live_img_preview entry={entry} class="h-full w-full object-cover" />
                      <% end %>
                    <% else %>
                      <span class="text-xs text-zinc-300">Upload</span>
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
                  placeholder="Tell the world about yourself in one line or less (or more if you'd like)..."
                  phx-debounce="300"
                  phx-change="welcome_bio_change"
                  class="min-h-[100px] w-full rounded-xl bg-dark-theater-primary text-mystery-white
                 placeholder:text-zinc-500 outline-none ring-1 ring-zinc-700
                 focus:ring-2 focus:ring-neon-blue-lightest/80 px-4 py-3"
                >{@welcome_bio}</textarea>
                <p class="mt-2 text-xs text-zinc-500 text-left">
                  Don't worry you can edit these details anytime in your profile settings.
                </p>
              </div>
              
    <!-- Actions: full-width on mobile, right-aligned on md+ -->
              <div class="flex flex-col md:flex-row justify-end gap-3 pt-1 md:pt-2">
                <.button
                  type="button"
                  color="secondary"
                  class="w-full md:w-auto"
                  phx-click="dismiss_welcome"
                >
                  Skip for now
                </.button>
                <.button type="submit" color="primary" class="w-full md:w-auto">
                  Save
                </.button>
              </div>
            </.simple_form>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end

  def handle_info(:connected, socket) do
    presence =
      socket.assigns.showcase.exhibitions
      |> Enum.map(fn ex ->
        presence_topic = PubSubTopics.presence_topic(ex.theater_id)
        Phoenix.PubSub.subscribe(Timesink.PubSub, presence_topic)
        {presence_topic, Presence.list(presence_topic)}
      end)
      |> Enum.into(%{})

    {:noreply, assign(socket, :presence, presence)}
  end

  def handle_info({:process_welcome_avatar, _ref}, socket) do
    outcomes =
      consume_uploaded_entries(socket, :welcome_avatar, fn %{path: path}, entry ->
        plug = %Plug.Upload{
          path: path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        user = load_user!(socket.assigns.current_user.id)

        profile =
          case user.profile do
            %Timesink.Account.Profile{} = p -> p
            _ -> raise "User has no profile loaded; cannot attach avatar"
          end

        case Timesink.Account.Profile.attach_avatar(profile, plug, user_id: user.id) do
          {:ok, _att} -> {:ok, :attached}
          {:error, reason} -> {:ok, {:attach_error, reason}}
        end
      end)

    outcome =
      Enum.find_value(outcomes, fn
        {:attach_error, _} = err -> err
        :attached -> :attached
        _ -> nil
      end) || :noop

    IO.inspect("sneind update!")

    case outcome do
      :attached ->
        user = reload_user_with_avatar!(socket.assigns.current_user.id)
        new_url = Profile.avatar_url(user.profile.avatar)

        # update nav + cache
        send_update(TimesinkWeb.NavAvatarLive, id: "nav-avatar-#{user.id}", avatar_url: new_url)
        IO.inspect("sneind update!")

        UserCache.put(%{
          id: user.id,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          avatar_url: new_url
        })

        {:noreply, assign(socket, welcome_avatar_error: nil)}

      {:attach_error, reason} ->
        {:noreply,
         assign(socket,
           welcome_avatar_error: friendly_err(reason)
         )}

      :noop ->
        IO.inspect("sneind update!")

        {:noreply, socket}
    end
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

    # 1) Attach image only if the user picked one; get URL from the returned attachment
    {avatar_url, attached?} =
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

    # 2) Update bio
    params = %{"profile" => %{"id" => profile.id, "bio" => to_string(bio)}}

    case Timesink.Account.User.update(user, params) do
      {:ok, updated_user} ->
        # Prefer the URL we just built from the attachment; if none, fall back to current
        final_url = avatar_url || Timesink.Account.Profile.avatar_url(updated_user.profile.avatar)

        if attached? do
          send_update(TimesinkWeb.NavAvatarLive,
            id: "nav-avatar-#{updated_user.id}",
            avatar_url: final_url
          )
        end

        Timesink.UserCache.put(%{
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
         |> put_flash(:info, "Profile updated — welcome!")}

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

  defp reload_user_with_avatar!(id), do: load_user!(id)

  defp friendly_err(%Ecto.Changeset{}), do: "Validation failed"
  defp friendly_err(%RuntimeError{message: m}), do: m
  defp friendly_err(%{message: m}) when is_binary(m), do: m
  defp friendly_err(term), do: term |> to_string() |> String.slice(0, 160)
end
