defmodule TimesinkWeb.FilmSubmission.StepPaymentComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Cinema.FilmSubmission


  def update(assigns, socket) do
    data = assigns[:data] || %{}

    data =
      Map.new(data, fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} -> {k, v}
      end)

    changeset = FilmSubmission.changeset(%FilmSubmission{}, data)

    {:ok,
     socket
     |> assign(method: assigns[:method] || nil)
     |> assign(btcpay_invoice: assigns[:btcpay_invoice] || nil)
     |> assign(btcpay_loading: assigns[:btcpay_loading] || false)
     |> assign(form: to_form(changeset), data: data)
     |> assign(:stripe_public_key, Timesink.Payment.Stripe.config().publishable_key)}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full px-6" id="film-submission-form-payment">
      <div class="max-w-6xl mx-auto flex flex-col md:flex-row gap-12">
        <!-- Payment Form -->
        <div class="md:w-1/2 space-y-6">
          <h2 class="text-3xl font-brand">Payment Details</h2>
          <p class="text-gray-300">Secure your submission with a $25.00 programming fee.</p>
          <%= if is_nil(@method) do %>
            <p class="text-sm text-gray-400 mt-4">Please choose a payment method to continue.</p>
          <% end %>
          <!-- Method toggle -->
          <div class="flex gap-4 mt-4">
            <button
              type="button"
              phx-click="select_method"
              phx-value-method="bitcoin"
              phx-target={@myself}
              class={[
                "px-4 py-2 rounded font-semibold border transition flex items-center gap-2",
                @method == "bitcoin" && "bg-orange-500 text-white border-orange-400 shadow",
                @method != "bitcoin" &&
                  "bg-backroom-black  border-orange-400 text-orange-400 hover:text-orange-300 hover:border-orange-300"
              ]}
            >
              ₿
              Pay with
              Bitcoin {if @method == "bitcoin", do: raw("✓"), else: ""}
            </button>
            <button
              type="button"
              phx-click="select_method"
              phx-value-method="card"
              phx-target={@myself}
              class={[
                "px-4 py-2 rounded font-semibold border transition",
                @method == "card" && "bg-white text-black border-white shadow",
                @method != "card" && "bg-gray-800 text-gray-300 hover:bg-gray-700 border-gray-700"
              ]}
            >
              Credit / Debit Card {if @method == "card", do: raw("✓"), else: ""}
            </button>
          </div>

          <%= if @method == "card" do %>
            <form
              id="stripe-payment-form"
              phx-hook="StripePayment"
              phx-target={@myself}
              data-stripe-key={@stripe_public_key}
            >
            <div id="card-element" class="p-4 rounded-xl bg-obsidian border border-dark-theater-medium shadow-md"></div>

              <div id="card-errors" class="text-red-500 text-sm mt-2"></div>

              <div class="text-sm text-gray-400 mt-4">
                Note: This is a placeholder. No actual payment will be processed.
              </div>

              <button
                type="submit"
                class="mt-6 bg-white text-black font-semibold px-6 py-3 rounded-md shadow hover:bg-gray-100 transition"
              >
                Pay & Submit
              </button>
            </form>
          <% end %>
          <%= if @method == "bitcoin" do %>
            <div class="mt-6 bg-gray-900/60 border border-gray-800 rounded-lg p-6 space-y-4">
              <h4 class="text-lg font-bold text-orange-400 flex items-center gap-2">
                &#8383; Bitcoin Payment
              </h4>

              <%= if @btcpay_invoice do %>
                <div class="space-y-4 text-center">
                  <a
                    href={@btcpay_invoice["checkoutLink"]}
                    target="_blank"
                    class="inline-block w-full bg-orange-500 text-white font-semibold px-6 py-3 rounded-md shadow hover:bg-orange-400 transition"
                  >
                    Open Bitcoin Checkout
                  </a>

                  <p class="text-sm text-gray-400">
                    You will be redirected to BTCPay to complete your transaction.
                  </p>

                  <p class="text-xs text-gray-500 mt-2">
                    ⚠️ Invoices usually expire after 15 minutes. Please complete payment promptly.
                  </p>
                </div>
              <% else %>
                <button
                  type="button"
                  phx-click="create_btcpay_invoice"
                  phx-target={@myself}
                  class="w-full border border-orange-500 text-orange-400 font-semibold px-6 py-3 rounded-md shadow hover:bg-orange-500/10 transition"
                >
                  <%= if @btcpay_loading do %>
                    <span class="inline-flex items-center">
                      <svg
                        aria-hidden="true"
                        role="status"
                        class="inline w-4 h-4 me-3 text-orange-600 animate-spin"
                        viewBox="0 0 100 101"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path
                          d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                          fill="#ffa366"
                        />
                        <path
                          d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                          fill="currentColor"
                        />
                      </svg>
                      Generating Bitcoin Invoice...
                    </span>
                  <% else %>
                    Generate Bitcoin Invoice
                  <% end %>
                </button>
              <% end %>
            </div>
          <% end %>
        </div>

    <!-- Review Box (unchanged) -->
        <div class="md:w-1/2">
          <div class="bg-gray-950/70 border border-gray-800 rounded-lg p-6 shadow-inner">
            <h3 class="text-xl font-semibold text-white mb-4">Review Submission</h3>
            <dl class="space-y-4 text-sm text-gray-300">
              <div>
                <dt class="font-medium text-gray-400">Contact Name</dt>
                <dd>{@data["contact_name"] || "—"}</dd>
              </div>
              <div>
                <dt class="font-medium text-gray-400">Contact Email</dt>
                <dd>{@data["contact_email"] || "—"}</dd>
              </div>
              <div>
                <dt class="font-medium text-gray-400">Film Title</dt>
                <dd>{@data["title"] || "—"}</dd>
              </div>
              <div>
                <dt class="font-medium text-gray-400">Synopsis</dt>
                <dd>{@data["synopsis"] || "No synopsis provided."}</dd>
              </div>
              <div>
                <dt class="font-medium text-gray-400">Video URL</dt>
                <dd>{@data["video_url"] || "—"}</dd>
                <%= if @data["video_pw"] && @data["video_pw"] != "" do %>
                  <dd class="text-xs text-gray-500">Password: {@data["video_pw"]}</dd>
                <% end %>
              </div>
              <div class="pt-6 border-t border-gray-800">
                <dt class="font-semibold text-white">Total</dt>
                <dd class="text-lg font-bold text-white">$25.00</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # Card payment selected – create Stripe PaymentIntent
  def handle_event("select_method", %{"method" => "card"}, socket) do
    user = socket.assigns.data["user"] || %{}
    amount = 2500

    case Timesink.Payment.Stripe.create_payment_intent(%{
           amount: amount,
           currency: "usd",
           metadata: %{user_id: user.id || "guest"}
         }) do
      {:ok, %Stripe.PaymentIntent{client_secret: secret}} ->
        socket =
          socket
          |> assign(:method, "card")
          |> push_event("stripe_client_secret", %{client_secret: secret})

        {:noreply, socket}

      {:error, err} ->
        Logger.error("Stripe error: #{inspect(err)}")
        {:noreply, assign(socket, :method, "card")}
    end
  end

  # Bitcoin selected – create BTCPay invoice
  def handle_event("select_method", %{"method" => "bitcoin"}, socket) do
    {:noreply, assign(socket, :method, "bitcoin")}
  end

  # Default case (future methods, validation, etc.)
  def handle_event("select_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, :method, method)}
  end

  def handle_event("update_form", %{"card_number" => _}, socket) do
    {:noreply, socket}
  end

  def handle_event("submit_payment", _params, socket) do
    send(
      self(),
      {:update_data, %{params: %{payment_id: "mock_#{System.system_time(:millisecond)}"}}}
    )

    send(self(), {:advance_step})
    {:noreply, socket}
  end

  def handle_event("create_btcpay_invoice", _, socket) do
    user = socket.assigns.data["user"]
    user_id = if is_map(user), do: user.id, else: nil

    metadata = %{
      user_id: user_id,
      contact_email: socket.assigns.data["contact_email"]
    }

    send(self(), {:create_btcpay_invoice, metadata})
    {:noreply, socket}
  end
end
