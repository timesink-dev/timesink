defmodule TimesinkWeb.Onboarding.StepVerifyEmailComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok,
     assign(socket,
       user_data: %{:email => "aaronzomback@gmail.com"},
       code: ["", "", "", "", "", ""]
     )}
  end

  def handle_event("update_code", %{"index" => index, "value" => value}, socket) do
    IO.inspect("update_code", label: "update_code sss")
    index = String.to_integer(index)
    code = List.replace_at(socket.assigns.code, index, String.slice(value, 0, 1))

    # Move focus to the next field if a digit was entered
    if value != "" do
      send(self(), {:focus_next, index + 1})
    end

    {:noreply, assign(socket, code: code)}
  end

  def handle_event("backspace", %{"index" => index}, socket) do
    index = String.to_integer(index)
    code = List.replace_at(socket.assigns.code, index, "")

    # Move focus back if the field is empty
    if index > 0 do
      send(self(), {:focus_next, index - 1})
    end

    {:noreply, assign(socket, code: code)}
  end

  def handle_event("paste_code", %{"value" => value}, socket) do
    code = String.slice(value, 0, 6) |> String.graphemes()
    code = Enum.concat(code, List.duplicate("", 6 - length(code)))

    {:noreply, assign(socket, code: code)}
  end

  def handle_event("submit_code", _, socket) do
    full_code = Enum.join(socket.assigns.code, "")

    # Call verify_email with the full code
    send(self(), {:verify_email, full_code})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white text-center">
        <h1 class="text-2xl font-bold">Enter Your Verification Code</h1>
        <p class="text-gray-400 mt-2">
          We sent a 6-digit code to <strong>aaronzomback@gmail.com</strong>.
          Enter it below to verify your email.
        </p>

        <div class="flex justify-center mt-6 space-x-2">
          <%= for {digit, index} <- Enum.with_index(@code) do %>
            <.input
              name={index}
              type="text"
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              phx-keyup="update_code"
              phx-keydown="backspace"
              phx-hook="AutoFocus"
              phx-value-index={index}
              value={digit}
            />
          <% end %>
        </div>

        <.input type="text" class="hidden" name="bob2" value="" />

        <.button color="secondary" class="w-full py-3 mt-6 text-lg" phx-click="submit_code">
          Verify & Continue
        </.button>

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
end
