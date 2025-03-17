defmodule TimesinkWeb.OnboardingLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="onboarding">
      <h1>Welcome to Timesink!</h1>
      <p>Let's get you started.</p>
      <p>First, please enter your email address:</p>
      <input type="email" name="email" required />
      <button>Submit</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, email: ""), layout: {TimesinkWeb.Layouts, :empty}}
  end

  # def handle_event("submit", %{"email" => email}, socket) do
  #   case Token.create_invite(email) do
  #     {:ok, token} ->
  #       {:noreply, socket |> assign(:token, token) |> push_redirect(to: Routes.onboarding_path(socket, :invite))
  #     {:error, reason} ->
  #       {:noreply, socket |> assign(:error, reason)}
  #   end
  # end
end
