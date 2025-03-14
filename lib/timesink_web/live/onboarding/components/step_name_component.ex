defmodule TimesinkWeb.Onboarding.StepNameComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          Let’s get started with your full name. This will help personalize your experience and let everyone know who you are.
        </p>
        <.simple_form
          class="mt-6 space-y-4 w-full"
          phx-submit="save_name"
          phx-target={@myself}
          for={@user_data}
          as="user_data"
        >
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-300">First name</label>
              <.input
                type="text"
                name="first_name"
                required
                value=""
                input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
                error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
                placeholder="Enter your first name"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-300">Last name</label>
              <.input
                type="text"
                name="last_name"
                required
                value=""
                input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
                error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
                placeholder="Enter your last name"
              />
            </div>
          </div>

          <:actions>
            <div class="mt-6">
              <.button color="secondary" class="w-full py-2 text-lg">Continue</.button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def handle_event("save_name", params, socket) do
    send(self(), {:update_user_data, params})
    send(self(), {:go_to_step, "location"})
    {:noreply, socket}
  end
end
