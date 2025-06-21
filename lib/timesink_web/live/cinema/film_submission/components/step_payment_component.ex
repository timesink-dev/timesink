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

    if connected?(socket) do
      topic = "payment:film-submission:#{data["contact_email"]}"
      IO.inspect(topic, label: "Subscribing to payment topic in step payment")

      Phoenix.PubSub.subscribe(
        Timesink.PubSub,
        "payment:film-submission:#{data["contact_email"]}"
      )
    end

    changeset = FilmSubmission.changeset(%FilmSubmission{}, data)

    IO.inspect(assigns[:method], label: "StepPaymentComponent method")
    IO.inspect(assigns[:btcpay_invoice], label: "StepPaymentComponent invoice")
    IO.inspect(assigns[:id], label: "StepPaymentComponent assigns")

    method =
      case assigns do
        %{method: m} when is_binary(m) -> m
        _ -> "card"
      end

    {:ok,
     socket
     |> assign(method: assigns[:method] || nil)
     |> assign(btcpay_invoice: assigns[:btcpay_invoice] || nil)
     |> assign(btcpay_loading: assigns[:btcpay_loading] || false)
     |> assign(form: to_form(changeset), data: data)}
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
                  "bg-backroom-black  text-orange-300 hover:bg-gray-700 border-orange-300"
              ]}
              disabled={@btcpay_loading}
            >
              &#8383;
              Pay with Bitcoin {if @method == "bitcoin", do: raw("✓"), else: ""}
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
            <form phx-change="update_form" phx-target={@myself} class="space-y-6">
              <!-- Card inputs (same as before) -->
              <div>
                <label class="block text-sm font-medium text-gray-200">Card Number</label>
                <input
                  name="card_number"
                  placeholder="4242 4242 4242 4242"
                  class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                />
              </div>

              <div class="flex gap-4">
                <div class="flex-1">
                  <label class="block text-sm font-medium text-gray-200">Exp. Month</label>
                  <input
                    name="exp_month"
                    placeholder="MM"
                    class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                  />
                </div>
                <div class="flex-1">
                  <label class="block text-sm font-medium text-gray-200">Exp. Year</label>
                  <input
                    name="exp_year"
                    placeholder="YY"
                    class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-200">CVC</label>
                <input
                  name="cvc"
                  placeholder="CVC"
                  class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                />
              </div>

              <div class="text-sm text-gray-400">
                Note: This is a placeholder. No actual payment will be processed.
              </div>

              <button
                type="button"
                phx-click="submit_payment"
                phx-target={@myself}
                class="bg-white text-black font-semibold px-6 py-3 rounded-md shadow hover:bg-gray-100 transition"
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
                  Generate Bitcoin Invoice
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
    metadata = %{
      user_id: socket.assigns.data["user"].id,
      contact_email: socket.assigns.data["contact_email"]
    }

    send(self(), {:create_btcpay_invoice, metadata})
    {:noreply, socket}
  end
end
