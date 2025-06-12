defmodule TimesinkWeb.Onboarding.StepVerifyEmailComponent do
  alias Timesink.Accounts
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok,
     assign(socket,
       digits: List.duplicate("", 6),
       verification_code: nil,
       verification_error: nil
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white text-center">
        <h1 class="text-2xl font-bold">Enter Your Verification Code</h1>
        <p class="text-gray-400 mt-2">
          We sent a 6-digit code to <strong>{@data["email"]}</strong>.
          Enter it below to verify your email.
        </p>

        <form class="w-full" phx-submit="verify_code" phx-target={@myself}>
          <div class="flex gap-2 mt-6" phx-hook="CodeInputs" id="code-entry">
            <%= for {digit, index} <- Enum.with_index(@digits) do %>
              <input
                type="text"
                maxlength="1"
                inputmode="numeric"
                pattern="[0-9]*"
                data-index={index}
                name={"digit-#{index}"}
                class="w-full text-2xl text-center px-1 py-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
                value={digit}
                phx-value-index={index}
                id={"digit-#{index}"}
              />
            <% end %>
          </div>
          <%= if @verification_error do %>
            <span class="flex flex-col text-center items-center justify-center gap-x-1 text-neon-red-light my-2">
              <.icon name="hero-exclamation-circle-mini" class="h-6 w-6" />
              <p class="text-md mt-2">
                {@verification_error}
              </p>
            </span>
          <% end %>
          <.button color="primary" class="w-full py-3 mt-6 text-lg">
            Verify & Continue
          </.button>
        </form>

        <p class="text-gray-400 text-sm mt-6">
          Didn't receive a code?
          <button
            id="resend-btn"
            phx-click="send_verification_email"
            phx-target={@myself}
            phx-hook="Countdown"
            data-original-text="Resend Code"
            data-countdown="60"
            class="text-neon-blue-lightest hover:underline"
          >
            Resend Code
          </button>
        </p>
      </div>
    </div>
    """
  end

  def handle_event(
        "verify_code",
        %{
          "digit-0" => digit_1,
          "digit-1" => digit_2,
          "digit-2" => digit_3,
          "digit-3" => digit_4,
          "digit-4" => digit_5,
          "digit-5" => digit_6
        },
        socket
      ) do
    verification_code = Enum.join([digit_1, digit_2, digit_3, digit_4, digit_5, digit_6])
    email = socket.assigns[:data]["email"]

    with {:ok, :valid_code} <-
           valid_verification_code?(verification_code, email) do
      send(self(), :email_verified)
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      {:error, :invalid_or_expired} ->
        {:noreply, assign(socket, verification_error: "Invalid verification code")}
    end
  end

  def handle_event("send_verification_email", _params, socket) do
    email = socket.assigns.data["email"]

    if email != "" do
      with {:ok, :sent} <- Accounts.send_email_verification(email) do
        socket =
          socket |> push_event("start_countdown", %{to: "resend-btn", duration: 60})

        {:noreply, socket}
      else
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Could not resend code: #{inspect(reason)}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Missing email address.")}
    end
  end

  defp valid_verification_code?(code, email) do
    with {:ok, _token} <- Accounts.validate_email_verification_code(code, email) do
      {:ok, :valid_code}
    else
      _ -> {:error, :invalid_or_expired}
    end
  end
end
