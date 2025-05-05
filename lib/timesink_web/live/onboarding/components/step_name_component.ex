defmodule TimesinkWeb.Onboarding.StepNameComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Accounts.User

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    changeset = User.name_changeset(%User{}, data)

    {:ok, assign(socket, form: to_form(changeset), data: data)}
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
          phx-change="validate"
          phx-target={@myself}
          for={@form}
        >
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-300">First name</label>
              <.input
                type="text"
                field={@form[:first_name]}
                required
                input_class="w-full p-3 rounded text-mystery-white border-none"
                error_class="mt-2 text-sm text-neon-red-light"
                placeholder="Enter your first name"
                phx-debounce="500"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-300">Last name</label>
              <.input
                type="text"
                field={@form[:last_name]}
                required
                input_class="w-full p-3 rounded text-mystery-white border-none"
                error_class="mt-2 text-sm text-neon-red-light"
                placeholder="Enter your last name"
                phx-debounce="500"
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

  def handle_event("validate", %{"user" => name_params}, socket) do
    changeset =
      %User{}
      |> User.name_changeset(name_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_name", %{"user" => name_params}, socket) do
    changeset = User.name_changeset(%User{}, name_params)

    if changeset.valid? do
      send(self(), {:update_user_data, %{params: name_params}})
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
