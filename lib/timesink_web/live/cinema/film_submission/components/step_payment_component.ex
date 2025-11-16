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

    stripe_client_secret = data["stripe_client_secret"] || socket.assigns[:stripe_client_secret]

    socket =
      socket
      |> assign(method: assigns[:method] || "card")
      |> assign(btcpay_invoice: assigns[:btcpay_invoice] || nil)
      |> assign(btcpay_loading: assigns[:btcpay_loading] || false)
      |> assign(form: to_form(changeset), data: data)
      |> assign(:stripe_public_key, Timesink.Payment.Stripe.config().publishable_key)
      |> assign(:stripe_client_secret, stripe_client_secret)

    {:ok, socket}
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
              phx-value-method="card"
              phx-target={@myself}
              class={[
                "cursor-pointer px-4 py-2 rounded font-semibold border transition",
                @method == "card" && "bg-white text-black border-white shadow",
                @method != "card" && "bg-gray-800 text-gray-300 hover:bg-gray-700 border-gray-700"
              ]}
            >
              Credit / Debit Card {if @method == "card", do: raw("✓"), else: ""}
            </button>
            <button
              type="button"
              phx-click="select_method"
              phx-value-method="bitcoin"
              phx-target={@myself}
              class={[
                "cursor-pointer px-4 py-2 rounded font-semibold border transition flex items-center gap-2",
                @method == "bitcoin" && "bg-orange-500 text-white border-orange-400 shadow",
                @method != "bitcoin" &&
                  "bg-backroom-black  border-orange-400 text-orange-400 hover:text-orange-300 hover:border-orange-300"
              ]}
            >
              ₿
              Pay with
              Bitcoin {if @method == "bitcoin", do: raw("✓"), else: ""}
            </button>
          </div>

          <%= if @method == "card" do %>
            <div>
              <%= if @stripe_client_secret do %>
                <form
                  id="stripe-payment-form"
                  phx-hook="StripePayment"
                  data-stripe-key={@stripe_public_key}
                  data-stripe-secret={@stripe_client_secret}
                  data-contact-name={@data["contact_name"]}
                  data-contact-email={@data["contact_email"]}
                >
                  <div id="payment-element" />

                  <.button
                    id="stripe-submit"
                    type="submit"
                    aria-busy="false"
                    class="phx-submit-loading:opacity-60 mt-6 bg-white text-black font-semibold px-6 py-3 rounded-md shadow hover:bg-gray-100 transition
           inline-flex items-center justify-center gap-2"
                  >
                    <span>Pay &amp; Submit</span>
                    <!-- keep width stable even when not spinning -->
                    <span class="inline-flex items-center justify-center w-4 h-4" aria-hidden="true">
                    </span>
                  </.button>

                  <p id="card-errors" class="mt-3 text-sm text-red-400"></p>
                </form>
              <% else %>
                <div class="bg-gray-900/60 border border-gray-800 rounded-lg p-6 space-y-4">
                  <p class="text-sm text-gray-400">
                    Stripe client secret not available. Please try again later.
                  </p>
                </div>
              <% end %>
            </div>
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
                  disabled={@btcpay_loading}
                  aria-busy={to_string(@btcpay_loading)}
                  class={[
                    "cursor-pointer w-full border border-orange-500 text-orange-400 font-semibold px-6 py-3 rounded-md shadow transition flex items-center justify-center gap-2",
                    if(@btcpay_loading, do: "opacity-90 cursor-wait", else: "hover:bg-orange-500/10")
                  ]}
                >
                  <span>Generate Bitcoin Invoice</span>
                  <span class="inline-flex items-center justify-center w-4 h-4">
                    <%= if @btcpay_loading do %>
                      <svg
                        aria-hidden="true"
                        role="status"
                        class="w-4 h-4 animate-spin text-orange-400"
                        viewBox="0 0 24 24"
                        fill="none"
                      >
                        <circle
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="3"
                          opacity=".25"
                        />
                        <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" stroke-width="3" />
                      </svg>
                    <% end %>
                  </span>
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
    socket =
      socket
      |> assign(:method, "card")

    {:noreply, socket}
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
    user = socket.assigns[:current_user]
    user_id = (user && user.id) || nil

    metadata = %{
      title: socket.assigns.data["title"],
      year: socket.assigns.data["year"],
      duration_min: socket.assigns.data["duration_min"],
      synopsis: socket.assigns.data["synopsis"],
      video_url: socket.assigns.data["video_url"],
      video_pw: socket.assigns.data["video_pw"],
      contact_name: socket.assigns.data["contact_name"],
      contact_email: socket.assigns.data["contact_email"],
      status_review: socket.assigns.data["status_review"],
      review_notes: socket.assigns.data["review_notes"],
      payment_id: "mock_#{System.system_time(:millisecond)}",
      submitted_by_id: user_id
    }

    # 1) show spinner immediately
    send(self(), {:create_btcpay_invoice, metadata})
    {:noreply, assign(socket, :btcpay_loading, true)}
  end
end
