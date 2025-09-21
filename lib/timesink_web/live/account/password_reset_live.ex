defmodule TimesinkWeb.Account.PasswordResetLive do
  use TimesinkWeb, :live_view
  alias Timesink.Account, as: Account
  alias Timesink.Account.User

  def mount(%{"token" => token}, _session, socket) do
    case Account.get_user_by_reset_password_token(token) do
      %User{} = user ->
        {:ok,
         assign(socket,
           user: user,
           token: token,
           # start with empty form
           form: to_form(Account.preview_user_password_changeset(%{}), as: "user"),
           ok_token?: true,
           success?: false
         ), layout: {TimesinkWeb.Layouts, :empty}}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "That reset link is invalid or expired.")
         |> assign(ok_token?: false), layout: {TimesinkWeb.Layouts, :empty}}
    end
  end

  def render(%{ok_token?: false} = assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-backroom-black px-4">
      <div class="w-full max-w-md bg-backroom-black bg-opacity-70 border border-dark-theater-medium rounded-2xl p-10 text-center">
        <h1 class="text-2xl font-semibold text-mystery-white">Reset password</h1>
        <p class="text-dark-theater-lightest mt-2">Please request a new link.</p>
        <.link navigate={~p"/reset-password"} class="text-brand hover:underline mt-4 inline-block">
          Get a new link
        </.link>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-backroom-black px-4">
      <div class="w-full max-w-md bg-backroom-black bg-opacity-70 border border-dark-theater-medium rounded-2xl p-10">
        <!-- Logo -->
        <a class="flex flex-col items-center mb-6" href={~p"/"}>
          <p class="text-4xl font-brand text-white tracking-tight">TimeSink</p>
          <p class="text-center text-sm text-dark-theater-lightest mt-2">Choose a new password</p>
        </a>

        <.simple_form for={@form} phx-change="validate" phx-submit="save" class="space-y-5">
          <.input
            type="password"
            field={@form[:password]}
            placeholder="New password"
            phx-debounce="400"
            input_class="w-full p-3 rounded-lg text-mystery-white focus:ring-2 focus:ring-neon-blue-light focus:outline-none"
            disabled={@success?}
          />
          <.input
            type="password"
            field={@form[:password_confirmation]}
            placeholder="Confirm password"
            phx-debounce="400"
            input_class="w-full p-3 rounded-lg text-mystery-white focus:ring-2 focus:ring-neon-blue-light focus:outline-none"
            disabled={@success?}
          />

          <:actions>
            <button
              type="submit"
              phx-disable-with="Updating..."
              disabled={@success?}
              aria-disabled={@success?}
              class="w-full mt-4 px-4 py-3 bg-neon-blue-lightest text-backroom-black font-bold rounded-lg
                      hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-neon-blue
                      disabled:opacity-50 disabled:cursor-not-allowed phx-submit-loading:opacity-60 phx-submit-loading:cursor-wait"
            >
              <span class="phx-submit-loading:hidden">Update password</span>
              <span class="hidden phx-submit-loading:inline">Updating…</span>
            </button>
          </:actions>
        </.simple_form>
        
    <!-- Success banner -->
        <div
          :if={@success?}
          class="mt-4 text-sm text-green-400 bg-green-500/10 border border-green-500/40 rounded-lg px-3 py-2 text-center"
        >
          Password updated successfully.
          <.link navigate={~p"/sign-in"} class="underline font-medium ml-1">Back to Sign In</.link>
        </div>
      </div>
    </div>
    """
  end

  # Debounced, “soft” validation - no required confirmation until present
  def handle_event("validate", %{"user" => params}, socket) do
    cs =
      params
      |> Account.preview_user_password_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(cs, as: "user"))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Account.reset_user_password(socket.assigns.user, params) do
      {:ok, _} ->
        {:noreply,
         assign(socket,
           success?: true,
           form: to_form(Account.preview_user_password_changeset(%{}), as: "user")
         )}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs, as: "user"))}
    end
  end
end
