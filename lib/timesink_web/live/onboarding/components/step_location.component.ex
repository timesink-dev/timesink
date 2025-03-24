defmodule TimesinkWeb.Onboarding.StepLocationComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Locations

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       form: to_form(%{}),
       suggestions: [],
       query: "",
       selected_location: nil,
       error: nil
     )}
  end

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    location = get_in(data, ["profile", "location"]) || %{}

    {:ok,
     socket
     |> assign(:data, data)
     |> assign(:form, to_form(location))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <h2 class="text-xl text-center mb-4">Where are you based?</h2>
        <.form
          for={@form}
          phx-target={@myself}
          phx-submit="save_location"
          phx-change="suggest_location"
        >
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-300">City</label>
            <.input
              type="text"
              name="locality"
              value={@form[:locality].value}
              phx-debounce="500"
              input_class="w-full p-3 rounded bg-dark-theater-primary border-none text-white"
              placeholder="Start typing your city (e.g. Los Angeles)"
            />
          </div>

          <%= if @suggestions != [] do %>
            <ul class="bg-white text-black rounded-md shadow-md divide-y divide-gray-200 mb-4">
              <%= for suggestion <- @suggestions do %>
                <li
                  phx-click="select_location"
                  phx-value-city={suggestion.city}
                  phx-value-country={suggestion.country}
                  phx-value-state={suggestion.state}
                  phx-value-lat={suggestion.lat}
                  phx-value-lng={suggestion.lng}
                  class="cursor-pointer px-4 py-2 hover:bg-gray-100"
                >
                  {suggestion.label}
                </li>
              <% end %>
            </ul>
          <% end %>
          
    <!-- Hidden fields that will be sent when form is submitted -->
          <.input type="hidden" name="lat" value={@form[:lat].value} />
          <.input type="hidden" name="lng" value={@form[:lng].value} />
          <.input type="hidden" name="country" value={@form[:country].value} />
          <.input type="hidden" name="state" value={@form[:state].value} />

          <div class="mt-6">
            <.button color="secondary" class="w-full py-2 text-lg">
              Continue <.icon name="hero-arrow-right" class="ml-1 h-6 w-6" />
            </.button>
          </div>
        </.form>

        <.button color="none" class="mt-6 p-0" phx-click="go_back" phx-target={@myself}>
          <.icon name="hero-arrow-left-circle" class="h-6 w-6" />
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("suggest_location", %{"locality" => locality}, socket) do
    with {:ok, suggestions} <- Locations.autocomplete_city(locality) do
      IO.inspect(suggestions, label: "here suggestions")
      {:noreply, assign(socket, suggestions: suggestions)}
    else
      _ -> {:noreply, assign(socket, suggestions: [], error: "Autocomplete failed")}
    end
  end

  def handle_event("select_location", params, socket) do
    # Update form data with selected values
    location = %{
      "locality" => params["city"],
      "state" => params["state"],
      "country" => params["country"],
      "lat" => params["lat"],
      "lng" => params["lng"]
    }

    # Update both the form and clear suggestions
    {:noreply,
     socket
     |> assign(:form, to_form(location))
     |> assign(:suggestions, [])}
  end

  def handle_event("save_location", %{"locality" => _} = params, socket) do
    # You can validate here if needed
    send(self(), {:update_user_data, %{"profile" => %{"location" => params}}})
    send(self(), {:go_to_step, :next})
    {:noreply, socket}
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
