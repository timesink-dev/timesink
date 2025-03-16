defmodule TimesinkWeb.Onboarding.StepUsernameComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Accounts

  def mount(socket) do
    changeset = Accounts.User.username_changeset(%Accounts.User{})
    {:ok, assign(socket, form: to_form(changeset), error: nil)}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
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
          for={@form}
          as="data"
        >
          <div>
            <label class="block text-sm font-medium text-gray-300">@</label>

            <.input
              type="text"
              name="username"
              phx-debounce="700"
              required
              field={@form[:username]}
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              placeholder="Claim your username (e.g. @tspresents)"
            />

            <%= if @form[:username] != "" && @error == nil do %>
              <.icon name="hero-check-circle-mini" class="h-6 w-6 text-green-500" />
            <% end %>

            <%= if @form[:username] != "" && @error do %>
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
                Take me in ! <.icon name="hero-arrow-right" class="ml-1 h-6 w-6" />
              </.button>
            </div>
          </:actions>
        </.simple_form>
        <.button class="mt-6 p-0" phx-click="go_back" phx-target={@myself}>
          <.icon name="hero-arrow-left-circle" class="h-6 w-6" />
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("complete_onboarding", _params, socket) do
    user_params =
      socket.assigns.data

    IO.inspect(user_params, label: "submit user params")

    with {:ok, _} <- Accounts.create_user(user_params) do
      # send(self(), :complete_onboarding)
      {:noreply, socket}
    else
      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "❌ User Creation Error")

        {:noreply, socket |> put_flash!(:error, "Something went wrong. Please try again.")}
    end
  end

  def handle_event("validate", %{"username" => username} = _username_params, socket) do
    with {:ok, :available} <- Accounts.is_username_available?(username) do
      changeset = Accounts.User.username_changeset(%Accounts.User{}, %{username: username})
      send(self(), {:update_user_data, to_form(changeset)})

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

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
