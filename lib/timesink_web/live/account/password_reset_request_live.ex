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
      <div class="w-full max-w-md bg-backroom-black bg-opacity-70 border border-dark-theater-medium rounded-2xl p-10">
        <!-- Logo -->
        <a class="flex flex-col items-center mb-6" href={~p"/"}>
          <p class="text-4xl font-brand text-white tracking-tight">TimeSink</p>
          <p class="text-center text-sm text-dark-theater-lightest mt-2">Reset your password</p>
        </a>
        
    <!-- Reset Request Form -->
        <.simple_form for={@form} as="req" phx-submqit="send" class="space-y-5">
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
              <%= if @sent? do %>
                <span class="flex justify-center items-center gap-x-1">
                  <.icon name="hero-check-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
                  Request link sent
                </span>
              <% else %>
                Send request link
              <% end %>
            </.button>
          </:actions>
        </.simple_form>
        
    <!-- Success hint -->
        <div :if={@sent?} class="mt-4 text-sm text-dark-theater-lightest">
          If your email is in our system, you’ll receive a link shortly.
        </div>
      </div>
    </div>
    """
  end

  def handle_event("send", %{"req" => %{"email" => email}}, socket) do
    email = email |> String.trim() |> String.downcase()

    Account.deliver_user_reset_password_instructions(email, fn token ->
      url(~p"/reset-password/#{token}")
    end)

    {:noreply, assign(socket, form: to_form(%{"email" => email}, as: "req"), sent?: true)}
  end
end
