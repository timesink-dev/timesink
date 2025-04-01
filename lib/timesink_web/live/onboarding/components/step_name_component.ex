defmodule TimesinkWeb.Onboarding.StepNameComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Accounts.User

  def update(assigns) do
    data = %{
      "first_name" => assigns[:data]["first_name"] || "",
      "last_name" => assigns[:data]["last_name"] || ""
    }

    first_name = Map.get(data, "first_name", "")
    last_name = Map.get(data, "last_name", "")

    changeset =
      User.name_changeset(%User{}, %{"first_name" => first_name, "last_name" => last_name})

    {:ok, assign(assigns, data: data, form: to_form(changeset))}
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
          for={@data}
          as="data"
        >
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-300">First name</label>
              <.input
                type="text"
                name="first_name"
                required
                value={@data["first_name"]}
                input_class="w-full p-3 rounded text-mystery-white border-none"
                placeholder="Enter your first name"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-300">Last name</label>
              <.input
                type="text"
                name="last_name"
                required
                value={@data["last_name"]}
                input_class="w-full p-3 rounded text-mystery-white border-none"
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

  def handle_event("save_name", name_params, socket) do
    send(self(), {:update_user_data, to_form(name_params)})
    send(self(), {:go_to_step, :next})
    {:noreply, socket}
  end

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
