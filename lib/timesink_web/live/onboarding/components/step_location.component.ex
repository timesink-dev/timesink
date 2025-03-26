defmodule TimesinkWeb.Onboarding.StepLocationComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Locations

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    location = Map.get(data["profile"] || %{}, "location", %{})

    label = location["label"]

    socket =
      socket
      |> assign(assigns)
      |> assign(:query, label || "")
      |> assign(:results, [])
      |> assign(:selected_location, location)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <h1 class="text-3xl font-bold text-center">Where are you joining us from?</h1>
        <p class="text-gray-400 text-center mt-2">
          We're building TimeSink together. Knowing where our community comes from helps shape our world and future screenings.
        </p>

        <form class="mt-6 space-y-4" phx-change="search" phx-target={@myself} phx-submit="continue">
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">City</label>
            <input
              type="text"
              name="query"
              value={@query}
              phx-debounce="300"
              placeholder="Start typing your city (e.g., Los Angeles)"
              class="w-full p-3 rounded text-white border-none bg-dark-theater-primary"
              autocomplete="off"
            />
          </div>

          <ul
            :if={@results != []}
            class="bg-dark-theater-primary shadow-md rounded mt-2 text-mystery-white max-h-60 overflow-auto"
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
              class="cursor-pointer px-4 py-2 hover:bg-zinc-700"
            >
              {result.label}
            </li>
          </ul>

          <.button class="mt-6 w-full py-3 text-lg" color="secondary">
            Continue
          </.button>
        </form>

        <.button color="none" class="mt-6 p-0" phx-click="go_back" phx-target={@myself}>
          <.icon name="hero-arrow-left-circle" class="h-6 w-6" />
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    with {:ok, results} <- Locations.get_locations(query) do
      {:noreply, assign(socket, results: results, query: query)}
    end
  end

  def handle_event(
        "select",
        %{
          "id" => id,
          "city" => city,
          "country_code" => country_code,
          "country" => country,
          "label" => label
        } = params,
        socket
      ) do
    state_code = params["state_code"] || nil

    with {:ok, %{lat: lat, lng: lng}} <- Locations.lookup_place(id) do
      location = %{
        "locality" => city,
        "state_code" => state_code,
        "country_code" => country_code,
        "country" => country,
        "label" => label,
        "lat" => lat,
        "lng" => lng
      }

      data = socket.assigns.data

      updated_data =
        update_in(data["profile"]["location"], fn _ -> location end)

      send(self(), {:update_user_data, %{params: updated_data}})

      {:noreply, assign(socket, selected_location: location, results: [], query: label)}
    else
      _ ->
        # Fallback if lookup fails (no lat/lng)
        location = %{
          "locality" => city,
          "state_code" => state_code,
          "country_code" => country_code,
          "country" => country,
          "label" => label,
          "lat" => nil,
          "lng" => nil
        }

        {:noreply, assign(socket, selected_location: location, results: [], query: label)}
    end
  end

  def handle_event("continue", _params, socket) do
    data = socket.assigns.data
    location = socket.assigns.selected_location

    if location do
      updated_data =
        update_in(data["profile"]["location"], fn _ -> location end)

      send(self(), {:update_user_data, %{params: updated_data}})
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please select a location before continuing.")}
    end
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
