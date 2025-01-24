defmodule TimesinkWeb.SignInLive do
  use TimesinkWeb, :live_view
  alias Timesink.Auth

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form),
     temporary_assigns: [form: form], layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm text-mystery-white">
      <.header class="text-center">
        Sign in
        <:subtitle>
          Not a member?
          <.link navigate={~p"/users/register"} class="text-brand hover:underline">
            Join the Waitlist
          </.link>
        </:subtitle>
      </.header>

      <.simple_form for={@form} as="user" id="sign_in_form" phx-submit="sign_in" phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <%!-- <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" /> --%>
          <.link href={~p"/users/reset_password"} class="text-sm">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("sign_in", %{"user" => sign_in_params}, socket) do
    with {:ok, user, _token} <- Auth.authenticate(sign_in_params) do
      {:noreply,
       socket
       |> put_flash(:info, "Welcome back!")
       |> redirect(to: ~p"/")}
    else
      :error ->
        form =
          to_form(
            Auth.password_auth_changeset(%{}, sign_in_params),
            as: "user",
            action: ~p"/users/log_in"
          )

        {:noreply, assign(socket, form: form)}
    end
  end
end
