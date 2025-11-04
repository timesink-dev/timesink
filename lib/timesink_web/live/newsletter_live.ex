defmodule TimesinkWeb.NewsletterLive do
  use TimesinkWeb, :live_component
  alias Timesink.Newsletter.Resend

  @impl true
  def mount(socket) do
    {:ok, assign(socket, status: :idle, error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto mt-16 border-t border-mystery-white/10 pt-10">
      <p class="text-lg font-semibold mb-2 text-center">
        Get screening updates & Cinematic transmissions from our newsletter
      </p>
      <p class="text-sm text-center text-mystery-white/70 mb-4 font-gangster w-2/3 mx-auto">
        Be the first to know about upcoming films, special events, and platform news, just the good stuff.
      </p>

      <%= if @status in [:idle, :error, :submitting] do %>
        <form
          phx-target={@myself}
          phx-submit="subscribe"
          class="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <!-- Honeypot -->
          <input type="text" name="website" autocomplete="off" tabindex="-1" class="hidden" />

          <input
            type="email"
            name="email"
            required
            placeholder="Your email"
            class="font-gangster bg-transparent border border-mystery-white/20 text-sm px-4 py-2 rounded w-2/3 sm:w-72 focus:outline-none focus:ring-2 focus:ring-primary"
          />
          <.button
            type="submit"
            color="primary"
            class="font-gangster w-2/3 sm:w-32"
            disabled={@status == :submitting}
          >
            {if @status == :submitting, do: "Subscribing…", else: "Subscribe"}
          </.button>
        </form>

        <%= if @error do %>
          <p class="mt-3 text-center text-red-300 text-sm">{@error}</p>
        <% end %>
      <% else %>
        <div class="text-center">
          <p class="mx-auto w-1/3 font-gangster text-sm bg-em bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 rounded py-2">
            You’re in. Check your inbox 📬
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("subscribe", %{"email" => email} = params, socket) do
    # Honeypot drop (treat as success to avoid tips to bots)
    if Map.get(params, "website", "") != "" do
      {:noreply, assign(socket, status: :success, error: nil)}
    else
      with :ok <- validate_email(email) do
        socket = assign(socket, status: :submitting, error: nil)

        case Resend.subscribe(email) do
          {:ok, _} ->
            Timesink.Newsletter.Mail.send_newsletter_welcome(email)
            {:noreply, assign(socket, status: :success)}

          {:error, {:http_error, 422, body}} ->
            {:noreply, assign(socket, status: :error, error: humanize_422(body))}

          {:error, {:http_error, _status, _body}} ->
            {:noreply, assign(socket, status: :error, error: "Unable to subscribe right now.")}

          {:error, {:transport_error, _reason}} ->
            {:noreply, assign(socket, status: :error, error: "Network error. Please try again.")}
        end
      else
        {:error, msg} -> {:noreply, assign(socket, status: :error, error: msg)}
      end
    end
  end

  defp validate_email(email) do
    cond do
      !is_binary(email) -> {:error, "Please enter a valid email."}
      String.length(email) > 254 -> {:error, "Email is too long."}
      !String.contains?(email, "@") -> {:error, "Please enter a valid email."}
      true -> :ok
    end
  end

  defp humanize_422(body) do
    case body do
      %{"error" => %{"message" => msg}} -> msg
      %{"message" => msg} -> msg
      _ -> "Please check your email and try again."
    end
  end
end
