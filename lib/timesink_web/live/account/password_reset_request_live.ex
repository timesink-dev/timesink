defmodule TimesinkWeb.Account.PasswordResetRequestLive do
  use TimesinkWeb, :live_view
  alias Timesink.Account, as: Account

  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "req")
    {:ok, assign(socket, form: form, sent?: false), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-backroom-black px-4">
      <div class="w-full max-w-md bg-backroom-black bg-opacity-70 border border-dark-theater-medium rounded-2xl p-10 text-center transition-all">
        <!-- Logo -->
        <a href={~p"/"} class="flex flex-col items-center mb-8">
          <p class="text-4xl font-brand text-white tracking-tight">TimeSink</p>
          <p class="text-center text-sm text-dark-theater-lightest mt-2">Reset your password</p>
        </a>
        
    <!-- Success state -->
        <div
          :if={@sent?}
          class="animate-fade-in flex flex-col items-center justify-center text-center"
        >
          <div class="flex flex-col items-center justify-center w-full rounded-xl border border-emerald-500/30 bg-emerald-500/10 py-4 px-4">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-emerald-500/20 border border-emerald-500/40 mb-4">
              <.icon name="hero-check-circle" class="h-8 w-8 text-emerald-400" />
            </div>
            <h2 class="text-lg font-semibold text-white">Request link sent</h2>
            <p class="text-sm text-emerald-100/90 max-w-xs">
              If your email is in our system, you’ll receive an emailed link shortly.
            </p>
          </div>
        </div>
        
    <!-- Request form -->
        <.simple_form
          :if={!@sent?}
          for={@form}
          as="req"
          phx-submit="send"
          class="space-y-5 animate-fade-in"
        >
          <.input
            field={@form[:email]}
            type="email"
            placeholder="Email"
            required
            input_class="w-full p-3 rounded-lg text-mystery-white focus:ring-2 focus:ring-neon-blue-light focus:outline-none"
          />
          <:actions>
            <.button
              phx-disable-with="Sending..."
              class="w-full mt-4 px-4 py-3 bg-neon-blue text-backroom-black font-bold rounded-lg hover:bg-neon-blue-lightest focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-neon-blue"
            >
              Send request link
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def handle_event("send", %{"req" => %{"email" => email}}, socket) do
    email = email |> String.trim() |> String.downcase()

    Account.deliver_user_reset_password_instructions(email, fn token ->
      url(~p"/reset-password/#{token}")
    end)

    {:noreply, assign(socket, sent?: true)}
  end
end
