defmodule TimesinkWeb.Onboarding.StepUsernameComponent do
  use TimesinkWeb, :live_component
  import Ecto.Changeset
  alias Timesink.Account.User
  alias Timesink.Account
  import Phoenix.HTML.Form

  def update(assigns, socket) do
    data = assigns[:data] || %{}
    username = Map.get(data, "username", "")
    changeset = User.username_changeset(%User{}, %{"username" => username})

    {:ok,
     socket
     |> assign(form: to_form(changeset), error: nil, data: data)
     |> assign_new(:loading?, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <p class="text-gray-400 text-center mt-2">
          Claim your handle. This will be your public identity on TimeSink.
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
                phx-debounce="400"
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
                <p class="text-md mt-2">{@error}</p>
              </span>
            <% end %>
          </div>

          <:actions>
            <div class="mt-6">
              <.button
                color="primary"
                classes={[
                  "w-full py-3 text-lg inline-flex items-center justify-center gap-2",
                  (@loading? && "opacity-80 cursor-not-allowed") || ""
                ]}
                disabled={@loading?}
                phx-disable-with=" "
              >
                <%= if @loading? do %>
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
                  <span>Completing your membership…</span>
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
        classes={["mt-6 p-0 text-center", (@loading? && "opacity-50 cursor-not-allowed") || ""]}
        phx-click="go_back"
        phx-target={@myself}
        disabled={@loading?}
      >
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
      {:noreply, assign(socket, loading?: true)}
    else
      error_message =
        user_create_changeset
        |> Ecto.Changeset.traverse_errors(&translate_error/1)
        |> Enum.map(fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
        |> Enum.join(". ")

      {:noreply,
       assign(socket, form: to_form(user_create_changeset), error: error_message, loading?: false)}
    end
  end

  def handle_event("validate", %{"username" => username} = username_params, socket) do
    changeset = User.username_changeset(%User{}, username_params)

    with {:ok, :available} <- Account.is_username_available?(username),
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
