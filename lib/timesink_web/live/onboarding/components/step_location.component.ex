defmodule TimesinkWeb.Onboarding.StepLocationComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Locations
  alias Timesink.Account.Location

  def update(assigns, socket) do
    location_data = get_in(assigns.data, ["profile", "location"]) || %{}
    changeset = Timesink.Account.Location.changeset(%Timesink.Account.Location{}, location_data)
    form = to_form(changeset, as: "location")

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:results, fn -> [] end)
     |> assign(:form, form)
     |> assign(:query, location_data["label"] || "")
     |> assign(:selected_location, location_data)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-screen bg-backroom-black px-4 sm:px-6 py-4">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-4 sm:p-8 text-white">
        <p class="text-base text-mystery-white text-center mb-3 sm:mb-4">
          Let's finalize your membership...
        </p>
        <h1 class="text-2xl font-bold text-center">Where are you joining us from?</h1>
        <p class="text-sm sm:text-base text-gray-400 text-center mt-2">
          At TimeSink we're building a global community. Knowing where you come from helps shape our world and future screenings.
        </p>

        <.simple_form
          for={@form}
          as="location"
          phx-submit="save_location"
          phx-target={@myself}
          class="mt-4 sm:mt-6"
        >
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">City</label>
            <input
              type="text"
              name="location_query"
              value={@query}
              required
              phx-debounce="200"
              phx-change="search"
              phx-target={@myself}
              placeholder="Start typing your city (e.g., Lyon, France)"
              class="w-full p-2 sm:p-3 rounded text-white border-none bg-dark-theater-primary focus:outline-none focus:ring-2 focus:ring-neon-blue-lightest text-sm sm:text-base"
              autocomplete="off"
            />
          </div>

          <ul
            :if={@results != []}
            class="bg-dark-theater-primary shadow-md rounded mt-2 text-mystery-white max-h-40 sm:max-h-60 overflow-auto text-sm sm:text-base"
          >
            <li
              :for={result <- @results}
              phx-click="select"
              phx-value-id={result.place_id}
              phx-value-label={result.label}
              phx-value-city={result.city}
              phx-value-state_code={result.state_code}
              phx-value-country_code={result.country_code}
              phx-value-country={result.country}
              phx-target={@myself}
              class="cursor-pointer px-3 sm:px-4 py-2 hover:bg-zinc-700"
            >
              {result.label}
            </li>
          </ul>
          <:actions>
            <.button class="mt-4 sm:mt-6 w-full py-2 sm:py-3 text-base sm:text-lg" color="primary">
              Continue
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <%!-- <.button
        color="none"
        class="mt-4 sm:mt-6 p-0 text-center text-sm sm:text-base"
        phx-click="go_back"
        phx-target={@myself}
      >
        ← Back
      </.button> --%>
    </div>
    """
  end

  def handle_event("search", %{"location_query" => q}, socket) do
    q = String.trim(q || "")

    if q == "" do
      {:noreply, assign(socket, results: [], query: "")}
    else
      with {:ok, results} <- Locations.get_locations(q) do
        {:noreply, assign(socket, results: results, query: q)}
      else
        _ -> {:noreply, assign(socket, results: [], query: q)}
      end
    end
  end

  def handle_event("select", params, socket) do
    %{
      "id" => id,
      "city" => city,
      "country_code" => country_code,
      "country" => country,
      "label" => label
    } = params

    state_code = params["state_code"] || nil

    with {:ok, %{lat: lat, lng: lng}} <- Locations.lookup_place(id) do
      selected_location = %{
        "locality" => city,
        "state_code" => state_code,
        "country_code" => country_code,
        "country" => country,
        "label" => label,
        "lat" => lat,
        "lng" => lng
      }

      form = to_form(Location.changeset(%Location{}, selected_location), as: "location")

      {:noreply,
       assign(socket,
         selected_location: selected_location,
         form: form,
         query: label,
         results: []
       )}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to retrieve full location info. Try again.")}
    end
  end

  def handle_event("save_location", _params, socket) do
    location = socket.assigns.selected_location
    changeset = Timesink.Account.Location.changeset(%Location{}, location)

    if changeset.valid? do
      updated_location =
        socket.assigns.data
        |> Map.update("profile", %{"location" => location}, fn profile ->
          Map.put(profile, "location", location)
        end)

      send(self(), {:update_user_data, %{params: updated_location}})
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      form = to_form(changeset, as: "location")

      {:noreply,
       socket
       |> assign(:form, form)
       |> put_flash(:error, "Please select a valid location before continuing.")}
    end
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
