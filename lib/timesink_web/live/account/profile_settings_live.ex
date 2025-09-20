defmodule TimesinkWeb.Accounts.ProfileSettingsLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts.{User, Profile, Location}
  alias Timesink.Locations
  alias Timesink.Repo

  def mount(_params, _session, socket) do
    user =
      socket.assigns.current_user
      |> Repo.preload(profile: [avatar: [:blob]])

    changeset = User.changeset(user)

    # Seed location UX state from existing profile.location when present
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
        dirty: false
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
            <!-- Avatar -->
            <.inputs_for :let={pf} field={@account_form[:profile]}>
              <div class="flex items-center gap-4">
                <div class="relative">
                  <%= if @user.profile && @user.profile.avatar do %>
                    <img
                      src={Profile.avatar_url(@user.profile.avatar)}
                      alt="Profile picture"
                      class="rounded-full w-14 h-14 object-cover ring-2 ring-zinc-700"
                    />
                  <% else %>
                    <span class="inline-flex h-14 w-14 items-center justify-center rounded-full bg-zinc-700 text-lg font-semibold text-mystery-white ring-2 ring-zinc-700">
                      {@user.first_name |> String.first() |> String.upcase()}
                    </span>
                  <% end %>
                </div>
                <div class="text-sm text-zinc-400">
                  <div class="font-medium text-zinc-200">Avatar</div>
                  <div>Image uploads coming soon.</div>
                </div>
                <.input type="hidden" field={pf[:id]} value={@user.profile.id} />
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
                  This helps us plan screenings and build local community.
                </p>
              </div>
              
    <!-- Bio -->
              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">Bio</label>
                <.input
                  field={pf[:bio]}
                  type="textarea"
                  placeholder="Tell the world about yourself"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3 min-h-[120px]"
                  value={@user.profile.bio}
                />
              </div>
            </.inputs_for>
            
    <!-- Account fields -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
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
                <p class="mt-2 text-xs text-zinc-500">Your handle for chat and credits.</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">Email</label>
                <.input
                  type="email"
                  field={@account_form[:email]}
                  value={@user.email}
                  placeholder="you@example.com"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                  class="md:relative"
                  error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
                />
              </div>

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
            </div>

            <:actions>
              <button
                type="submit"
                disabled={!@dirty}
                aria-disabled={!@dirty}
                class="w-full md:w-auto px-6 py-3 rounded-xl font-semibold bg-neon-blue-lightest text-backroom-black
          hover:opacity-90 focus:ring-2 focus:ring-neon-blue-lightest focus:outline-none transition
          disabled:opacity-40 disabled:cursor-not-allowed phx-submit-loading:opacity-60 phx-submit-loading:cursor-wait"
                phx-disable-with="Updating…"
              >
                <span class="inline-flex items-center gap-2 phx-submit-loading:hidden">
                  Save changes
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
              </button>
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
      Timesink.Accounts.User.changeset(socket.assigns.user, params)
      |> Map.put(:action, :validate)

    loc_dirty? =
      location_changed?(
        socket.assigns.user.profile && socket.assigns.user.profile.location,
        socket.assigns.selected_location
      )

    {:noreply, assign(socket, account_form: to_form(cs), dirty: cs.changes != %{} or loc_dirty?)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    username = user_params["username"] |> to_string() |> String.trim_leading("@")

    updated_params =
      user_params
      |> Map.put("username", username)
      |> ensure_location_payload(socket.assigns.selected_location)

    with {:ok, updated_user} <- User.update(socket.assigns.user, updated_params) do
      {:noreply,
       socket
       |> assign(
         user: updated_user,
         account_form: to_form(User.changeset(updated_user)),
         # ✅ new baseline
         selected_location: to_location_map(updated_user.profile.location),
         dirty: false
       )
       |> put_flash(:info, "Profile updated successfully")}
    else
      {:error, cs} ->
        {:noreply, assign(socket, account_form: to_form(cs))}
    end
  end

  # def handle_event("loc_select", params, socket) do
  #   # ... build `selected` the same way you already do ...
  #   case Locations.lookup_place(id) do
  #     {:ok, %{lat: lat, lng: lng}} ->
  #       selected = %{
  #         "locality" => city,
  #         "state_code" => state_code,
  #         "country_code" => country_code,
  #         "country" => country,
  #         "label" => label,
  #         "lat" => lat,
  #         "lng" => lng
  #       }

  #       dirty =
  #         location_changed?(
  #           socket.assigns.user.profile && socket.assigns.user.profile.location,
  #           selected
  #         )

  #       {:noreply,
  #        socket
  #        |> assign(selected_location: selected, loc_query: label, loc_results: [], dirty: dirty)}

  #     _ ->
  #       {:noreply, put_flash(socket, :error, "Failed to retrieve full location info. Try again.")}
  #   end
  # end

  # --- helpers ---

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
    IO.inspect(Map.take(cur, keys) != Map.take(selected || %{}, keys))
    Map.take(cur, keys) != Map.take(selected || %{}, keys)
  end
end
