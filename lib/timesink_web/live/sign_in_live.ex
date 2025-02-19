defmodule TimesinkWeb.SignInLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false),
     layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm text-mystery-white">
      <.header class="text-center">
        Sign in
        <:subtitle>
          Not a member?
          <.link navigate={~p"/join"} class="text-brand hover:underline">
            Join the Waitlist
          </.link>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        as="user"
        id="sign_in_form"
        method="post"
        phx-update="ignore"
        action={~p"/sign_in"}
      >
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <%!-- <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" /> --%>
          <%!-- <.link href={~p"/users/reset_password"} class="text-sm">
            Forgot your password?
          </.link> --%>
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
end
