defmodule TimesinkWeb.Account.ProfileSettingsLive do
  use TimesinkWeb, :live_view

  alias Timesink.Account.{User, Profile, Location}
  alias Timesink.{Locations, Repo}
  alias Timesink.UserCache

  def mount(_params, _session, socket) do
    user =
      Repo.get!(Timesink.Account.User, socket.assigns.current_user.id)
      |> Repo.preload(profile: [avatar: [:blob]])

    changeset = User.changeset(user)

    {loc_query, selected_location} =
      case user.profile && user.profile.location do
        %Location{label: label} = loc when is_binary(label) -> {label, to_location_map(loc)}
        %Location{locality: city, country: c} = loc -> {"#{city}, #{c}", to_location_map(loc)}
        _ -> {"", %{}}
      end

    socket =
      socket
      |> assign(
        user: user,
        account_form: to_form(changeset),
        loc_query: loc_query,
        loc_results: [],
        selected_location: selected_location,
        dirty: false,
        # ← avatar upload ready but not persisted yet
        avatar_ready: false,
        # ← showing upload progress
        avatar_processing: false,
        # ← error message to show near control
        avatar_error: nil
      )
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .webp .heic),
        max_entries: 1,
        max_file_size: 8_000_000,
        # upload starts as soon as a file is picked
        auto_upload: true,
        progress: &handle_avatar_progress/3
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-8">
      <div class="max-w-2xl mx-auto">
        <.back navigate={~p"/me"}></.back>
      </div>

      <div class="w-full max-w-2xl mx-auto bg-backroom-black/60 backdrop-blur">
        <div class="px-6 md:px-8 py-6 border-b border-zinc-800">
          <h2 class="text-2xl md:text-3xl font-semibold text-mystery-white text-center">
            Profile settings
          </h2>
          <p class="text-zinc-400 text-center mt-2">
            Keep your profile fresh so folks know who’s in the theater.
          </p>
        </div>

        <div class="px-6 md:px-8 py-6">
          <.simple_form
            for={@account_form}
            as="user"
            phx-change="validate"
            phx-submit="save"
            class="space-y-8"
          >
            <.inputs_for :let={pf} field={@account_form[:profile]}>
              <div class="grid grid-cols-1 md:grid-cols-[auto,1fr] items-start gap-4 md:gap-6">
                <div class="relative mx-auto">
                  <form
                    phx-change="upload_avatar"
                    phx-auto-recover="ignore"
                    class={[@avatar_processing && "pointer-events-none opacity-60", "cursor-pointer"]}
                  >
                    <label class="cursor-pointer block">
                      <!-- Avatar image or initials -->
                      <%= if @uploads.avatar.entries != [] do %>
                        <%= for entry <- @uploads.avatar.entries do %>
                          <.live_img_preview
                            entry={entry}
                            class="rounded-full w-16 h-16 md:w-20 md:h-20 object-cover ring-2 ring-zinc-700"
                          />
                        <% end %>
                      <% else %>
                        <%= if @user.profile && @user.profile.avatar do %>
                          <% url = Profile.avatar_url(@user.profile && @user.profile.avatar) %>
                          <img
                            src={url}
                            class="rounded-full w-16 h-16 md:w-20 md:h-20 object-cover ring-2 ring-zinc-700"
                          />
                        <% else %>
                          <span class="inline-flex h-16 w-16 md:h-20 md:w-20 items-center justify-center rounded-full bg-zinc-700 text-xl md:text-2xl font-semibold text-mystery-white ring-2 ring-zinc-700">
                            {initials(@user)}
                          </span>
                        <% end %>
                      <% end %>

                      <span class="absolute -bottom-1 -right-1 items-center rounded-full bg-emerald-600/90 text-xs text-white px-2 py-0.5">
                        You
                      </span>
                      
    <!-- Subtle loading overlay while processing -->
                      <div
                        :if={@avatar_processing}
                        class="absolute inset-0 rounded-full bg-black/40 grid place-items-center"
                      >
                        <svg
                          class="animate-spin h-5 w-5 text-white"
                          viewBox="0 0 24 24"
                          fill="none"
                          aria-hidden="true"
                        >
                          <circle
                            class="opacity-25"
                            cx="12"
                            cy="12"
                            r="10"
                            stroke="currentColor"
                            stroke-width="4"
                          />
                          <path
                            class="opacity-75"
                            fill="currentColor"
                            d="M4 12a8 8 0 018-8v4A4 4 0 008 12H4z"
                          />
                        </svg>
                      </div>

                      <.live_file_input upload={@uploads.avatar} class="hidden" />
                    </label>
                  </form>
                  <p :if={@avatar_error} class="text-xs text-red-400 mt-1 text-center md:text-left">
                    {@avatar_error}
                  </p>
                </div>
                
    <!-- Username column -->
                <div class="w-full mt-4 md:mt-0">
                  <label class="block text-sm font-medium text-zinc-300 mb-2">Username</label>
                  <div class="relative">
                    <span class="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400">@</span>
                    <input
                      type="text"
                      name={@account_form[:username].name}
                      value={@user.username}
                      class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3 pl-8"
                      placeholder="username"
                    />
                  </div>
                  <p class="mt-2 text-xs text-zinc-500 truncate">
                    Your public handle on the platform
                  </p>
                  <.input type="hidden" field={pf[:id]} value={@user.profile.id} />
                </div>
              </div>
              
    <!-- Location (Onboarding-style) -->
              <div class="mt-1">
                <label class="block text-sm font-medium text-zinc-300 mb-2">Location</label>
                
    <!-- Visible query box mirrors onboarding -->
                <input
                  type="text"
                  name="location_query"
                  value={@loc_query}
                  placeholder="Start typing your city (e.g., Los Angeles)"
                  phx-debounce="300"
                  phx-change="loc_search"
                  class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                  autocomplete="off"
                />
                
    <!-- Dropdown results -->
                <ul
                  :if={@loc_results != []}
                  class="bg-dark-theater-primary border border-zinc-700 shadow-md rounded-xl mt-2 text-mystery-white max-h-60 overflow-auto"
                >
                  <li
                    :for={result <- @loc_results}
                    phx-click="loc_select"
                    phx-value-id={result.place_id}
                    phx-value-label={result.label}
                    phx-value-city={result.city}
                    phx-value-state_code={result.state_code}
                    phx-value-country_code={result.country_code}
                    phx-value-country={result.country}
                    class="cursor-pointer px-4 py-2 hover:bg-zinc-700"
                  >
                    {result.label}
                  </li>
                </ul>
                
    <!-- Hidden nested fields posted with the form -->
                <.inputs_for :let={locf} field={pf[:location]}>
                  <.input
                    type="hidden"
                    field={locf[:id]}
                    value={@user.profile.location && @user.profile.location.id}
                  />
                  <input
                    type="hidden"
                    name={locf[:locality].name}
                    value={@selected_location["locality"] || ""}
                  />
                  <input
                    type="hidden"
                    name={locf[:state_code].name}
                    value={@selected_location["state_code"] || ""}
                  />
                  <input
                    type="hidden"
                    name={locf[:country_code].name}
                    value={@selected_location["country_code"] || ""}
                  />
                  <input
                    type="hidden"
                    name={locf[:country].name}
                    value={@selected_location["country"] || ""}
                  />
                  <input
                    type="hidden"
                    name={locf[:label].name}
                    value={@selected_location["label"] || ""}
                  />
                  <input type="hidden" name={locf[:lat].name} value={@selected_location["lat"] || ""} />
                  <input type="hidden" name={locf[:lng].name} value={@selected_location["lng"] || ""} />
                </.inputs_for>

                <p class="mt-2 text-xs text-zinc-500">
                  This helps us plan screenings and build our community.
                </p>
              </div>
              
    <!-- Bio -->
              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">Bio</label>
                <.input
                  field={pf[:bio]}
                  type="textarea"
                  placeholder="Tell the world about yourself..."
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3 min-h-[120px]"
                  value={@user.profile.bio}
                />
              </div>
            </.inputs_for>
            
    <!-- Account fields -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">First name</label>
                <.input
                  field={@account_form[:first_name]}
                  value={@user.first_name}
                  placeholder="First name"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">Last name</label>
                <.input
                  field={@account_form[:last_name]}
                  value={@user.last_name}
                  placeholder="Last name"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                />
              </div>

              <div>
                <div class="flex items-center justify-between mb-2">
                  <label class="block text-sm font-medium text-zinc-300">Email</label>
                  <%= if @user.unverified_email do %>
                    <span class="inline-flex items-center gap-1 rounded-full bg-amber-500/10 border border-amber-500/30 px-2 py-0.5 text-xs font-medium text-amber-400">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-3 w-3"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                          clip-rule="evenodd"
                        />
                      </svg>
                      Pending Verification
                    </span>
                  <% end %>
                </div>
                <.input
                  type="email"
                  field={@account_form[:email]}
                  value={@user.unverified_email || @user.email}
                  placeholder="you@example.com"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                  class="md:relative"
                  error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
                />
                <%= if @user.unverified_email do %>
                  <p class="mt-2 text-xs text-mystery-white">
                    We've sent a verification link to <span class="font-semibold">{@user.email}</span>.
                    Please check your inbox (and spam folder) to verify this change.
                  </p>
                <% end %>
              </div>
            </div>

            <:actions>
              <.button
                type="submit"
                disabled={!@dirty}
                aria-disabled={!@dirty}
                class="w-full md:w-2/3 px-6 py-3 bg-neon-blue-lightest text-backroom-black
          hover:opacity-90 focus:ring-2 focus:ring-neon-blue-lightest focus:outline-none transition
          disabled:opacity-40 disabled:cursor-not-allowed phx-submit-loading:opacity-60 phx-submit-loading:cursor-wait"
                phx-disable-with="Updating profile…"
              >
                <span class="inline-flex items-center gap-2 phx-submit-loading:hidden">
                  Update profile
                </span>
                <span class="hidden phx-submit-loading:inline-flex items-center gap-2">
                  <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8v4A4 4 0 008 12H4z"
                    >
                    </path>
                  </svg>
                  Updating…
                </span>
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </section>
    """
  end

  # --- Location search/select (mirrors onboarding) ---
  def handle_event("loc_search", %{"location_query" => query}, socket) do
    # When the user types, run the same search as onboarding
    with {:ok, results} <- Locations.get_locations(query) do
      {:noreply, assign(socket, loc_results: results, loc_query: query)}
    else
      _ -> {:noreply, assign(socket, loc_results: [], loc_query: query)}
    end
  end

  def handle_event("loc_select", params, socket) do
    %{
      "id" => id,
      "city" => city,
      "country_code" => country_code,
      "country" => country,
      "label" => label
    } = params

    state_code = Map.get(params, "state_code")

    case Locations.lookup_place(id) do
      {:ok, %{lat: lat, lng: lng}} ->
        selected = %{
          "locality" => city,
          "state_code" => state_code,
          "country_code" => country_code,
          "country" => country,
          "label" => label,
          "lat" => lat,
          "lng" => lng
        }

        # ✅ compute dirty here (this will also make your IO.inspect run)
        dirty =
          location_changed?(
            socket.assigns.user.profile && socket.assigns.user.profile.location,
            selected
          )

        {:noreply,
         socket
         |> assign(selected_location: selected, loc_query: label, loc_results: [], dirty: dirty)}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to retrieve full location info. Try again.")}
    end
  end

  def handle_event("validate", %{"user" => params}, socket) do
    params = Map.update(params, "username", nil, &String.trim_leading(to_string(&1), "@"))

    cs =
      Timesink.Account.User.changeset(socket.assigns.user, params)
      |> Map.put(:action, :validate)

    loc_dirty? =
      location_changed?(
        socket.assigns.user.profile && socket.assigns.user.profile.location,
        socket.assigns.selected_location
      )

    {:noreply,
     assign(socket,
       account_form: to_form(cs),
       dirty: cs.changes != %{} or loc_dirty? or socket.assigns.avatar_ready
     )}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    username = user_params["username"] |> to_string() |> String.trim_leading("@")
    current_user = socket.assigns.user
    new_email = user_params["email"] |> to_string() |> String.trim() |> String.downcase()
    # Only treat as email change if it's different from both current email AND unverified_email
    email_change_request? =
      new_email != current_user.email and new_email != current_user.unverified_email

    updated_params =
      user_params
      |> Map.put("username", username)
      # Remove email from params - we'll handle it separately if changed
      |> Map.delete("email")
      |> ensure_location_payload(socket.assigns.selected_location)

    # First update other fields (username, name, profile)
    with {:ok, updated_user} <- User.update(current_user, updated_params) do
      # Process avatar upload if ready
      {final_user, avatar_flash_type, avatar_flash_msg} =
        if socket.assigns.avatar_ready do
          process_pending_avatar(socket, updated_user)
        else
          {updated_user, nil, nil}
        end

      # If email changed, initiate email change verification flow
      updated_user_with_flash =
        if email_change_request? do
          case Timesink.Account.initiate_email_change(
                 final_user,
                 new_email,
                 fn token ->
                   url(~p"/auth/verify-email/#{token}")
                 end
               ) do
            {:ok, user_with_pending_email} ->
              msg =
                build_flash_message(
                  "Profile updated. We've sent a verification link to #{current_user.email}.",
                  avatar_flash_msg
                )

              socket
              |> assign(user: user_with_pending_email)
              |> put_flash(:info, msg)

            {:error, :email_already_in_use} ->
              msg =
                build_flash_message(
                  "That email address is already in use by another account.",
                  avatar_flash_msg
                )

              socket
              |> assign(user: final_user)
              |> put_flash(:error, msg)

            {:error, %Ecto.Changeset{} = cs} ->
              msg = build_flash_message("Failed to update email address.", avatar_flash_msg)

              socket
              |> assign(account_form: to_form(cs))
              |> put_flash(:error, msg)

            {:error, _reason} ->
              msg =
                build_flash_message(
                  "Failed to send verification email. Please try again.",
                  avatar_flash_msg
                )

              socket
              |> assign(user: final_user)
              |> put_flash(:error, msg)
          end
        else
          # Determine success message based on avatar upload result
          {flash_type, flash_msg} =
            case avatar_flash_type do
              :error ->
                {:error, avatar_flash_msg}

              _ ->
                {:success, build_flash_message("Profile updated successfully", avatar_flash_msg)}
            end

          socket
          |> assign(user: final_user)
          |> put_flash(flash_type, flash_msg)
        end

      {:noreply,
       updated_user_with_flash
       |> assign(
         account_form: to_form(User.changeset(updated_user_with_flash.assigns.user)),
         selected_location: to_location_map(final_user.profile.location),
         dirty: false,
         avatar_ready: false,
         avatar_processing: false
       )}
    else
      {:error, cs} ->
        {:noreply, assign(socket, account_form: to_form(cs))}
    end
  end

  # Fire once when client finished sending the file
  # Don't persist yet - wait for save button
  # Fire during upload progress - show spinner while uploading
  def handle_avatar_progress(:avatar, entry, socket) do
    if entry.done? do
      # Upload complete - hide spinner, mark ready for save
      {:noreply,
       assign(socket,
         avatar_processing: false,
         avatar_ready: true,
         avatar_error: nil,
         dirty: true
       )}
    else
      # Upload in progress - show spinner
      {:noreply, assign(socket, avatar_processing: true, avatar_error: nil)}
    end
  end

  def handle_info({:avatar_updated, user_id, url}, %{assigns: %{user: %{id: user_id}}} = socket) do
    user =
      Timesink.Repo.get!(Timesink.Account.User, user_id)
      |> Timesink.Repo.preload(profile: [avatar: [:blob]])

    # If you use a stateful avatar component:
    send_update(TimesinkWeb.NavAvatarLive,
      # id: "avatar-#{user_id}",
      avatar_url: url
    )

    {:noreply,
     socket
     |> assign(user: user, avatar_processing: false, avatar_error: nil)}
  end

  # Ignore updates for other users (good hygiene if you happen to be subscribed widely)
  def handle_info({:avatar_updated, _other_id, _url}, socket) do
    {:noreply, socket}
  end

  # Process pending avatar upload during save
  defp process_pending_avatar(socket, user) do
    outcomes =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        plug = %Plug.Upload{
          path: path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        case Timesink.Account.Profile.attach_avatar(user.profile, plug, user_id: user.id) do
          {:ok, _att} -> {:ok, :attached}
          {:error, reason} -> {:ok, {:attach_error, reason}}
        end
      end)

    # Pick first result (we only allow 1 entry anyway)
    outcome =
      Enum.find_value(outcomes, fn
        {:attach_error, _} = err -> err
        :attached -> :attached
        _ -> nil
      end) || :noop

    case outcome do
      :attached ->
        # Reload user with fresh avatar + blob
        reloaded_user =
          Repo.get!(Timesink.Account.User, user.id)
          |> Repo.preload(profile: [avatar: [:blob]])

        new_url = Profile.avatar_url(reloaded_user.profile.avatar)

        # Update nav avatar component
        send_update(
          TimesinkWeb.NavAvatarLive,
          id: "nav-avatar-#{user.id}",
          avatar_url: new_url
        )

        # Update user cache
        UserCache.put(%{
          id: user.id,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          avatar_url: new_url
        })

        {reloaded_user, :success, ""}

      {:attach_error, reason} ->
        {user, :error, "Failed to update avatar: #{friendly_err(reason)}"}

      :noop ->
        {user, nil, nil}
    end
  end

  # Build combined flash message with optional avatar message
  defp build_flash_message(main_msg, nil), do: main_msg

  defp build_flash_message(main_msg, avatar_msg) do
    "#{main_msg} #{avatar_msg}"
  end

  # If the nested location is empty (user didn't pick from dropdown), fall back to previous selection
  defp ensure_location_payload(params, selected_location) do
    case get_in(params, ["profile", "location"]) do
      %{} = loc when map_size(loc) > 0 ->
        params

      _ ->
        if selected_location == %{} do
          params
        else
          put_in(params, ["profile", "location"], selected_location)
        end
    end
  end

  defp to_location_map(%Location{} = loc) do
    %{
      "id" => loc.id,
      "locality" => loc.locality,
      "state_code" => loc.state_code,
      "country_code" => loc.country_code,
      "country" => loc.country,
      "label" => loc.label,
      "lat" => loc.lat,
      "lng" => loc.lng
    }
  end

  defp location_changed?(current_loc, selected) do
    cur =
      case current_loc do
        nil ->
          %{}

        loc ->
          %{
            "locality" => loc.locality,
            "state_code" => loc.state_code,
            "country_code" => loc.country_code,
            "country" => loc.country,
            "label" => loc.label,
            "lat" => loc.lat,
            "lng" => loc.lng
          }
      end

    # compare only relevant keys
    keys = ~w(locality state_code country_code country label lat lng)
    Map.take(cur, keys) != Map.take(selected || %{}, keys)
  end

  defp initials(%{first_name: fnm, last_name: lnm}) do
    f = fnm |> to_string() |> String.trim() |> String.first() || ""
    l = lnm |> to_string() |> String.trim() |> String.first() || ""

    case String.upcase(f <> l) do
      "" -> "?"
      s -> s
    end
  end

  defp friendly_err(%Ecto.Changeset{}), do: "Validation failed"
  defp friendly_err(%RuntimeError{message: m}), do: m
  defp friendly_err(%{message: m}) when is_binary(m), do: m
  defp friendly_err(term), do: term |> to_string() |> String.slice(0, 160)
end
