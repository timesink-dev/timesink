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
    <div class="min-h-screen flex items-center justify-center bg-backroom-black">
      <!-- Card container for the sign in form -->
      <div class="bg-backroom-black bg-opacity-70  rounded-lg shadow-lg p-8 w-full max-w-md h-[600px]">
        <!-- Logo and title -->
        <a class="flex flex-col items-center mb-6" href={~p"/"}>
          <p class="text-3xl font-brand leading-10 tracking-tighter text-white">
            TimeSink
          </p>
        </a>
        
    <!-- Sign in form -->
        <.simple_form
          for={@form}
          as="user"
          id="sign_in_form"
          method="post"
          phx-update="ignore"
          action={~p"/sign_in"}
          class="flex flex-col gap-y-4"
        >
          <.input
            field={@form[:email]}
            type="email"
            placeholder="Email"
            input_class="w-full p-2 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            placeholder="Password"
            input_class="w-full p-2 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            required
          />
          <.link
            navigate="/forgot_password"
            class="text-brand
            hover:underline text-sm text-left"
          >
            Forgot password
          </.link>
          <:actions>
            <.button
              phx-disable-with="Signing in..."
              class="w-full text-backroom-black font-semibold mt-4 px-4 py-2 hover:bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light rounded"
            >
              Sign in
            </.button>
          </:actions>
        </.simple_form>
        
    <!-- Footer for sign in form -->
        <.header class="text-center mt-4">
          <:subtitle>
            Not a member?
            <.link navigate={~p"/join"} class="text-brand hover:underline">
              Join the Waitlist
            </.link>
          </:subtitle>
        </.header>
      </div>
    </div>
    """
  end
end
