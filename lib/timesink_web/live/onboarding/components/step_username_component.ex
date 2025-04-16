defmodule TimesinkWeb.Onboarding.StepUsernameComponent do
  use TimesinkWeb, :live_component
  import Ecto.Changeset
  alias Timesink.Accounts.User
  alias Timesink.Accounts
  import Phoenix.HTML.Form

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    username = Map.get(data, "username", "")
    changeset = User.username_changeset(%User{}, %{"username" => username})
    {:ok, assign(socket, form: to_form(changeset), error: nil, data: data)}
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
          for={@form}
          as="data"
        >
          <div class="relative">
            <label class="block text-sm font-medium text-gray-300">Username</label>
            <div class="relative">
              <span class="absolute left-3 top-1/2 -translate-y-1/2 flex items-center text-mystery-white text-lg z-20">
                @
              </span>
              <.input
                type="text"
                name="username"
                phx-debounce="700"
                required
                field={@form[:username]}
                input_class="w-full pl-9 pr-10 py-3 text-mystery-white border-none"
                error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
                placeholder="Claim your unique handle"
              >
                <:addon_icon_right :if={username_valid?(@form, @error)}>
                  <.icon name="hero-check-circle-mini" class="h-5 w-5 text-green-500" />
                </:addon_icon_right>
              </.input>
            </div>

            <p
              class="text-sm mt-2 text-left text-dark-theater-lightest truncate w-full overflow-hidden whitespace-nowrap"
              title={"timesinkpresents.com/@" <> (input_value(@form, :username) || "yourhandle")}
            >
              timesinkpresents.com/@{input_value(@form, :username) || "yourhandle"}
            </p>
            <%= if input_value(@form, :username) != "" && @error do %>
              <span class="flex flex-col text-center items-center justify-center gap-x-1 text-neon-red-light mt-2">
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
                Take me in ! →
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>

      <.button color="none" class="mt-6 p-0 text-center" phx-click="go_back" phx-target={@myself}>
        ← Back
      </.button>
    </div>
    """
  end

  def handle_event("complete_onboarding", username_params, socket) do
    user_create_params =
      socket.assigns.data
      |> Map.merge(username_params)

    user_create_changeset = User.username_changeset(%User{}, user_create_params)

    if user_create_changeset.valid? do
      send(self(), {:complete_onboarding, to_form(user_create_changeset)})
      {:noreply, socket}
    else
      error_message =
        user_create_changeset
        |> Ecto.Changeset.traverse_errors(&translate_error/1)
        |> Enum.map(fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
        |> Enum.join(". ")

      {:noreply, assign(socket, form: to_form(user_create_changeset), error: error_message)}
    end
  end

  def handle_event("validate", %{"username" => username} = username_params, socket) do
    changeset = User.username_changeset(%User{}, username_params)

    with {:ok, :available} <- Accounts.is_username_available?(username),
         {:ok, _validated_data} <- apply_action(changeset, :validate) do
      send(self(), {:update_user_data, to_form(changeset)})

      {:noreply, assign(socket, form: to_form(changeset), error: nil)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          changeset
          |> Ecto.Changeset.traverse_errors(&translate_error/1)
          |> Enum.map(fn {_field, messages} -> "#{Enum.join(messages, ", ")}" end)

        {:noreply, assign(socket, error: Enum.join(error_message, ", "))}

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

  defp username_valid?(form, error) do
    input_value(form, :username) != "" and
      error == nil and
      !Keyword.has_key?(form.source.errors, :username)
  end
end
