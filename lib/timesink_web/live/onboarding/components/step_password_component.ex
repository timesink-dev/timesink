defmodule TimesinkWeb.Onboarding.StepPasswordComponent do
  use TimesinkWeb, :live_component
  import Ecto.Changeset

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    password = Map.get(data, "password", "")

    # Create a changeset for password validation
    changeset = password_changeset(%{"password" => password, "password_confirmation" => ""})

    {:ok,
     socket
     |> assign(form: to_form(changeset, as: "user"), data: data)
     |> assign_new(:show_password, fn -> false end)
     |> assign_new(:show_password_confirmation, fn -> false end)
     |> assign_new(:loading?, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-screen overflow-hidden bg-backroom-black px-4 sm:px-6 py-4">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-4 sm:p-8 text-white">
        <h1 class="text-2xl font-bold text-center">Create a secure password</h1>
        <p class="text-sm sm:text-base text-gray-400 text-center mt-2">
          Your password must be at least 8 characters long.
        </p>

        <.simple_form
          class="mt-4 sm:mt-6 space-y-3 sm:space-y-4 w-full"
          phx-submit="save_password"
          phx-change="validate"
          phx-target={@myself}
          for={@form}
        >
          <div class="space-y-3 sm:space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-300">Password</label>
              <div class="relative">
                <.input
                  type={(@show_password && "text") || "password"}
                  field={@form[:password]}
                  required
                  input_class="w-full px-3 pr-10 py-3 text-mystery-white border-none text-sm sm:text-base"
                  error_class="mt-1 sm:mt-2 text-xs sm:text-sm text-neon-red-light"
                  placeholder="Enter your password"
                  phx-debounce="500"
                  autocomplete="new-password"
                />
                <button
                  type="button"
                  phx-click="toggle_password_visibility"
                  phx-target={@myself}
                  class="absolute right-3 top-2 sm:top-3 text-gray-400 hover:text-gray-300"
                >
                  <.icon
                    name={(@show_password && "hero-eye-slash") || "hero-eye"}
                    class="h-4 w-4 sm:h-5 sm:w-5"
                  />
                </button>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-300">Confirm password</label>
              <div class="relative">
                <.input
                  type={(@show_password_confirmation && "text") || "password"}
                  field={@form[:password_confirmation]}
                  required
                  input_class="w-full px-3 pr-10 py-3 text-mystery-white border-none text-sm sm:text-base"
                  error_class="mt-1 sm:mt-2 text-xs sm:text-sm text-neon-red-light"
                  placeholder="Confirm your password"
                  phx-debounce="500"
                  autocomplete="new-password"
                />
                <button
                  type="button"
                  phx-click="toggle_password_confirmation_visibility"
                  phx-target={@myself}
                  class="absolute right-3 top-2 sm:top-3 text-gray-400 hover:text-gray-300"
                >
                  <.icon
                    name={(@show_password_confirmation && "hero-eye-slash") || "hero-eye"}
                    class="h-4 w-4 sm:h-5 sm:w-5"
                  />
                </button>
              </div>
            </div>
          </div>

          <:actions>
            <div class="mt-4 sm:mt-6">
              <.button
                color="primary"
                classes={[
                  "w-full py-3 text-base sm:text-lg inline-flex items-center justify-center gap-2",
                  (@loading? && "opacity-80 cursor-not-allowed") || ""
                ]}
                disabled={@loading?}
                phx-disable-with=" "
              >
                <%= if @loading? do %>
                  <span>Completing</span>
                  <svg
                    aria-hidden="true"
                    role="status"
                    class="inline w-4 h-4 animate-spin"
                    viewBox="0 0 100 101"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <!-- outer ring (dim) -->
                    <path
                      class="opacity-25"
                      fill="currentColor"
                      d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                    />
                    <!-- arc (spins) -->
                    <path
                      fill="currentColor"
                      d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                    />
                  </svg>
                <% else %>
                  <span>Complete and enter →</span>
                <% end %>
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>

      <.button
        color="none"
        classes={[
          "mt-4 sm:mt-6 p-0 text-center text-sm sm:text-base",
          (@loading? && "opacity-50 cursor-not-allowed") || ""
        ]}
        phx-click="go_back"
        phx-target={@myself}
        disabled={@loading?}
      >
        ← Back
      </.button>
    </div>
    """
  end

  def handle_event("toggle_password_visibility", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end

  def handle_event("toggle_password_confirmation_visibility", _params, socket) do
    {:noreply,
     assign(socket, show_password_confirmation: !socket.assigns.show_password_confirmation)}
  end

  def handle_event("validate", %{"user" => password_params}, socket) do
    changeset =
      password_params
      |> password_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def handle_event("save_password", %{"user" => password_params}, socket) do
    changeset = password_changeset(password_params)

    if changeset.valid? do
      # Only send the password field to user_data (not password_confirmation)
      password = get_change(changeset, :password)

      # Merge password into user_data and complete onboarding
      user_create_params =
        socket.assigns.data
        |> Map.put("password", password)

      send(self(), {:complete_onboarding, %{params: user_create_params}})
      {:noreply, assign(socket, loading?: true)}
    else
      {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end

  def handle_event("go_back", _unsigned_params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end

  # Private helper to create password changeset with confirmation validation
  defp password_changeset(params) do
    types = %{password: :string, password_confirmation: :string}

    {%{}, types}
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters")
    |> validate_confirmation(:password,
      message: "Password confirmation does not match"
    )
  end
end
