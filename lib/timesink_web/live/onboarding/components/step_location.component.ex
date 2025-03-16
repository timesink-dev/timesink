defmodule TimesinkWeb.Onboarding.StepLocationComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          As we build the world of TimeSink together, we want to know where you are all coming from.
        </p>
        <.simple_form
          class="mt-6 space-y-4 w-full"
          phx-submit="save_location"
          phx-target={@myself}
          for={@data}
          as="data"
        >
          <div>
            <label class="block text-sm font-medium text-gray-300">Where are you?</label>
            <.input
              type="text"
              name="location"
              required
              value={@data["location"]["locality"] || ""}
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              placeholder="Enter your location (e.g. New York, NY)"
            />
          </div>

          <:actions>
            <div class="mt-6">
              <.button color="secondary" class="w-full py-2 text-lg">Continue</.button>
            </div>
          </:actions>
        </.simple_form>
        <.button class="mt-6" phx-click="go_back" phx-target={@myself}>
          <.icon name="hero-arrow-left-circle" class="h-6 w-6" />
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("save_location", params, socket) do
    # send(self(), {:update_user_data, to_form(params)})
    send(self(), {:go_to_step, :next})
    {:noreply, socket}
  end

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
