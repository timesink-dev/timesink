defmodule TimesinkWeb.Onboarding.StepLocationComponent do
  use TimesinkWeb, :live_component
  import Ecto.Changeset

  alias Timesink.Locations

  def update(_assigns, socket) do
    {:ok,
     assign(socket,
       place: "",
       places: [
         %{
           title: "Los Angeles, CA",
           position: "34.0522,-118.2437"
         },
         %{
           title: "New York, NY",
           position: "40.7128,-74.0060"
         },
         %{
           title: "Chicago, IL",
           position: "41.8781,-87.6298"
         },
         %{
           title: "San Francisco, CA",
           position: "37.7749,-122.4194"
         },
         %{
           title: "Miami, FL",
           position: "25.7617,-80.1918"
         },
         %{
           title: "Austin, TX",
           position: "30.2672,-97.7431"
         },
         %{
           title: "Seattle, WA",
           position: "47.6062,-122.3321"
         },
         %{
           title: "Portland, OR",
           position: "45.5051,-122.6750"
         }
       ]
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          As we build the world of TimeSink together, we want to know where you are all coming from.
        </p>
        <form
          class="mt-6 space-y-4 w-full"
          phx-change="suggest"
          phx-submit="save_location"
          phx-target={@myself}
        >
          <div>
            <label class="block text-sm font-medium text-gray-300">Where are you?</label>
            <input
              type="text"
              required
              autocomplete="off"
              list="places"
              phx-debounce="700"
              placeholder="Enter your location (e.g. New York, NY)"
            />
            <datalist id="places">
              <%= for place <- @places do %>
                <option value={place.title}>{place.title}</option>
              <% end %>
            </datalist>
          </div>

          <div class="mt-6">
            <button color="secondary" class="w-full py-2 text-lg">Continue</button>
          </div>
        </form>
        <.button color="none" class="mt-6" phx-click="go_back" phx-target={@myself}>
          <.icon name="hero-arrow-left-circle" class="h-6 w-6" />
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("save_location", _params, socket) do
    # send(self(), {:update_user_data, to_form(params)})
    send(self(), {:go_to_step, :next})
    {:noreply, socket}
  end

  def handle_event("suggest", params, socket) do
    %{
      "place" => place,
      "position" => position
    } = params

    places =
      Locations.get_locations(place, position)

    {:noreply,
     assign(socket,
       places: places,
       place: place
     )}
  end

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
