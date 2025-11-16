defmodule TimesinkWeb.Onboarding.StepEmailComponent do
  use TimesinkWeb, :live_component

  import Phoenix.HTML.Form
  alias Timesink.Account
  alias Timesink.Account.User
  import Ecto.Changeset

  def mount(socket) do
    changeset = User.email_password_changeset(%User{})
    {:ok, assign(socket, form: to_form(changeset), error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <h1 class="text-3xl font-bold text-center">Welcome to TimeSink</h1>
        <p class="text-gray-400 text-center mt-2">
          Let’s Get You Set Up. Just a few quick steps before you’re in.
        </p>

        <.simple_form
          class="mt-6 space-y-4"
          phx-submit="send_verification_email"
          phx-target={@myself}
          for={@form}
          as="data"
        >
          <.input
            type="email"
            name="email"
            phx-debounce="700"
            phx-change="validate_email"
            required
            field={@form[:email]}
            input_class="w-full p-3 rounded text-mystery-white border-none"
            placeholder="Enter your email"
          >
            <:addon_icon_right :if={email_valid?(@form, @error)}>
              <.icon name="hero-check-circle" class="h-5 w-5 text-green-500" />
            </:addon_icon_right>
          </.input>

          <div>
            <label class="block text-sm font-medium text-gray-300">Password</label>
            <.input
              type="password"
              name="password"
              field={@form[:password]}
              required
              input_class="w-full p-3 rounded text-mystery-white border-none"
              placeholder="Create a password"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-300">Confirm Password</label>
            <.input
              type="password"
              name="password_confirmation"
              value=""
              required
              input_class="w-full p-3 rounded text-mystery-white border-none"
              placeholder="Confirm your password"
            />
          </div>

          <%= if input_value(@form, :email) !== "" && @error do %>
            <span class="flex flex-col text-center items-center justify-center gap-x-1 text-neon-red-light">
              <.icon name="hero-exclamation-circle-mini" class="h-6 w-6" />
              <p class="text-md mt-2">
                {@error}
              </p>
            </span>
          <% end %>

          <:actions>
            <div class="mt-6">
              <.button color="primary" class="w-full py-3 text-lg">Continue</.button>
            </div>
          </:actions>
        </.simple_form>

        <p class="text-gray-400 text-center text-sm mt-6">
          Your email will be used to confirm your account and notify you about new screenings.
        </p>
      </div>
    </div>
    """
  end

  def handle_event(
        "send_verification_email",
        %{
          "email" => email,
          "password" => password,
          "password_confirmation" => password_confirmation
        },
        socket
      ) do
    changeset =
      User.email_password_changeset(%Account.User{}, %{
        "email" => email,
        "password" => password
      })

    with {:ok, _validated_data} <- apply_action(changeset, :validate),
         {:ok, :available} <- Account.is_email_available?(email),
         {:ok, :matched} <- Account.verify_password_conformity(password, password_confirmation),
         {:ok, :sent} <- Account.send_email_verification(email) do
      send(self(), {:update_user_data, to_form(changeset)})
      send(self(), {:go_to_step, :next})
      {:noreply, assign(socket, form: to_form(changeset), error: nil)}
    else
      {:error, :email_taken} ->
        {:noreply,
         assign(socket, form: to_form(changeset), error: "This email is already being used.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          changeset
          |> Ecto.Changeset.traverse_errors(&translate_error/1)
          |> Enum.map(fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
          |> Enum.join(". ")

        {:noreply, assign(socket, form: to_form(changeset)) |> put_flash(:error, error_message)}

      {:error, :password_mismatch} ->
        {:noreply,
         assign(socket,
           form: to_form(changeset),
           error: "The password you have entered does not match."
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, to_string(reason))}
    end
  end

  def handle_event("validate_email", %{"email" => email}, socket) do
    changeset = User.email_password_changeset(%User{}, %{"email" => email})

    with {:ok, :available} <- Account.is_email_available?(email) do
      send(self(), {:update_user_data, to_form(changeset)})

      {:noreply, assign(socket, form: to_form(changeset), error: nil)}
    else
      {:error, :email_taken} ->
        {:noreply,
         assign(socket,
           error: "This email is already being used. Please try another."
         )}
    end
  end

  defp email_valid?(form, error) do
    input_value(form, :email) != "" and
      error == nil and
      !Keyword.has_key?(form.source.errors, :email)
  end

  # def handle_event("validate_password_strength", _unsigned_params, _socket) do
  # Passwords should conform to the following rules
  # - At least 8 characters
  # - At least 1 uppercase letter
  # - At least 1 lowercase letter
  # - At least 1 special character

  # The following regex pattern enforces the above rules
  # ^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W).{8,}$
  # end
end
