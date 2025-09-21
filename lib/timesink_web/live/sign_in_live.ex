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
    <div class="min-h-screen flex items-center justify-center bg-backroom-black px-4">
      <div class="w-full max-w-md bg-backroom-black bg-opacity-70 border border-dark-theater-medium rounded-2xl p-10">
        <!-- Logo -->
        <a class="flex flex-col items-center mb-6" href={~p"/"}>
          <p class="text-4xl font-brand text-white tracking-tight">TimeSink</p>
          <p class="text-center text-sm text-dark-theater-lightest mt-2">Welcome back</p>
        </a>
        
    <!-- Sign-in Form -->
        <.simple_form
          for={@form}
          as="user"
          id="sign_in_form"
          method="post"
          phx-update="ignore"
          action={~p"/sign-in"}
          class="space-y-5"
        >
          <.input
            field={@form[:email]}
            type="email"
            placeholder="Email"
            input_class="w-full p-3 rounded-lg text-mystery-white focus:ring-2 focus:ring-neon-blue-light focus:outline-none"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            placeholder="Password"
            input_class="w-full p-3 rounded-lg text-mystery-white focus:ring-2 focus:ring-neon-blue-light focus:outline-none"
            required
          />
          <div class="flex justify-between text-sm">
            <.link navigate="/reset-password" class="text-brand hover:underline">
              Forgot password?
            </.link>
          </div>
          <:actions>
            <.button
              phx-disable-with="Signing in..."
              class="w-full mt-4 px-4 py-3 bg-neon-blue text-backroom-black font-bold rounded-lg hover:bg-neon-blue-lightest focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-neon-blue"
            >
              Sign in
            </.button>
          </:actions>
        </.simple_form>
        
    <!-- Footer -->
        <div class="text-center mt-6 text-sm text-dark-theater-lightest">
          Not a member?
          <.link navigate={~p"/join"} class="text-brand hover:underline">
            Join the Waitlist
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
