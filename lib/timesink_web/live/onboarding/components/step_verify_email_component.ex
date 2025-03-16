defmodule TimesinkWeb.Onboarding.StepVerifyEmailComponent do
  alias Timesink.Accounts
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok,
     assign(socket,
       digits: ["", "", "", "", "", ""],
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
          <div class="flex gap-2 my-6" phx-hook="CodeInputs" id="code-entry">
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
            <span class="flex flex-col text-center items-center justify-center gap-x-1 text-neon-red-light">
              <.icon name="hero-exclamation-circle-mini" class="h-6 w-6" />
              <p class="text-md mt-2">
                {@verification_error}
              </p>
            </span>
          <% end %>
          <.button color="secondary" class="w-full py-3 mt-6 text-lg">
            Verify & Continue
          </.button>
        </form>

        <p class="text-gray-400 text-sm mt-6">
          Didn't receive a code?
          <button
            phx-click="send_verification_email"
            phx-value-email="aaronzomback@gmail.com"
            class="text-neon-blue-lightest hover:underline"
          >
            Resend Code
          </button>
        </p>
      </div>
    </div>
    """
  end

  def handle_event("update-digit", params, socket) do
    # Extract only the keys that match "digit-#" pattern
    digit_params =
      params
      |> Enum.filter(fn {key, _value} -> Regex.match?(~r/^digit-\d+$/, key) end)
      |> Enum.sort_by(fn {key, _} ->
        # Extract the digit index from "digit-#" key and convert to integer for sorting
        [_, index] = Regex.run(~r/digit-(\d+)/, key)
        String.to_integer(index)
      end)
      # Extract just the digit value
      |> Enum.map(fn {_key, value} -> String.slice(value, 0, 1) end)

    # Ensure the list has exactly 6 elements, filling with "" if necessary
    updated_digits = digit_params ++ List.duplicate("", max(0, 6 - length(digit_params)))

    {:noreply, assign(socket, digits: updated_digits)}
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

  # if String.length(verification_code) == 6 &&
  #      Enum.all?(socket.assigns.digits, fn digit -> digit != "" end) do
  #   # Here you would check if the verification code is valid
  #   # For example, by checking against a stored code in your database
  #   valid_code = valid_verification_code?(verification_code)

  #   if valid_code do
  #     # Mark the email as verified in your database
  #     # Redirect to a success page or dashboard
  #     {:noreply, push_redirect(socket, to: "/verified")}
  #   else
  #     {:noreply, assign(socket, verification_error: "Invalid verification code")}
  #   end
  # else
  #   {:noreply, assign(socket, verification_error: "Please enter all 6 digits")}
  # end

  # Replace with your actual verification logic
  defp valid_verification_code?(code, email) do
    with {:ok, _token} <- Accounts.validate_email_verification_code(code, email) do
      {:ok, :valid_code}
    else
      _ -> {:error, :invalid_or_expired}
    end
  end
end
