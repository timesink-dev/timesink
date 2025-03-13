defmodule TimesinkWeb.Onboarding.StepUsernameComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, user_data: socket.assigns[:user_data], username: "")}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          Lastly, claim a unique handle. This will be your identity on TimeSink.
        </p>
        <.simple_form
          class="mt-6 space-y-4 w-full"
          phx-submit="save_location"
          phx-change="validate"
          phx-target={@myself}
          for={@user_data}
          as="user_data"
        >
          <div>
            <label class="block text-sm font-medium text-gray-300">@</label>

            <.input
              type="text"
              name="username"
              required
              value={@username}
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              placeholder="Claim your username (e.g. @tspresents)"
            />
          </div>

          <:actions>
            <div class="mt-6">
              <.button color="secondary" class="w-full py-2 text-lg">
                Let's Go In! <.icon name="hero-arrow-right" class="ml-1 h-5 w-5" />
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def handle_event("save_name", params, socket) do
    socket =
      assign(socket,
        user_data: Map.put(socket.assigns[:user_data], "full_name", params["full_name"])
      )

    send(self(), {:go_to_step, "location"})
    {:noreply, socket}
  end

  def handle_event("validate", %{"username" => username}, socket) do
    IO.inspect(username, label: "foobar")

    formatted_username =
      username
      |> String.trim()
      # Ensures '@' is always present
      |> String.replace_prefix("", "@")

    socket = assign(socket, username: formatted_username)

    {:noreply, socket}
  end
end
