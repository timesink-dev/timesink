defmodule TimesinkWeb.Onboarding.StepUsernameComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Accounts

  def mount(socket) do
    {:ok, assign(socket, user_data: socket.assigns[:user_data], username: "", error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          Lastly, claim a unique handle. This will be your public identity on TimeSink.
        </p>
        <.simple_form
          class="mt-6 space-y-4 w-full"
          phx-submit="complete_onboarding"
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
              phx-debounce="700"
              required
              value={@username}
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              placeholder="Claim your username (e.g. @tspresents)"
            />

            <%= if @username != "" && @error == nil do %>
              <.icon name="hero-check-circle-mini" class="h-6 w-6 text-green-500" />
            <% end %>

            <%= if @username != "" && @error do %>
              <span class="flex flex-col text-center items-center justify-center gap-x-1 text-neon-red-light">
                <.icon name="hero-exclamation-circle-mini" class="h-6 w-6" />
                <p class="text-md mt-2">
                  {@error}
                </p>
              </span>
            <% end %>
          </div>

          <:actions>
            <div class="mt-6">
              <.button color="secondary" class="w-full py-2 text-lg">
                Take me in ! <.icon name="hero-arrow-right" class="ml-1 h-5 w-5" />
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def handle_event("complete_onboarding", params, socket) do
    with {:ok, _} <- Accounts.create_user(params) do
      send(self(), :complete_onboarding)
      {:noreply, socket}
    else
      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"username" => username}, socket) do
    with {:ok, :available} <- Accounts.is_username_available?(username) do
      {:noreply, assign(socket, username: username, error: nil)}
    else
      {:error, :username_taken} ->
        {:noreply,
         assign(socket,
           username: username,
           error: "This handle has already been claimed by someone else. Please try another."
         )}
    end
  end
end
