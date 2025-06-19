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

    {:ok, assign(socket, form: to_form(changeset), data: data)}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-6xl mx-auto flex flex-col md:flex-row gap-12">
        <!-- Payment Form -->
        <div class="md:w-1/2 space-y-6">
          <h2 class="text-3xl font-brand">Payment Details</h2>
          <p class="text-gray-300">Secure your submission with a $25.00 programming fee.</p>

          <form phx-change="update_form" phx-target={@myself}>
            <div class="grid grid-cols-1 gap-6">
              <!-- Card Number -->
              <div>
                <label class="block text-sm font-medium text-gray-200">Card Number</label>
                <input
                  type="text"
                  name="card_number"
                  placeholder="4242 4242 4242 4242"
                  class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                />
              </div>
              
    <!-- Expiration Date -->
              <div class="flex gap-4">
                <div class="flex-1">
                  <label class="block text-sm font-medium text-gray-200">Exp. Month</label>
                  <input
                    type="text"
                    name="exp_month"
                    placeholder="MM"
                    class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                  />
                </div>
                <div class="flex-1">
                  <label class="block text-sm font-medium text-gray-200">Exp. Year</label>
                  <input
                    type="text"
                    name="exp_year"
                    placeholder="YY"
                    class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                  />
                </div>
              </div>
              
    <!-- CVC -->
              <div>
                <label class="block text-sm font-medium text-gray-200">CVC</label>
                <input
                  type="text"
                  name="cvc"
                  placeholder="CVC"
                  class="w-full mt-1 px-4 py-2 rounded-md bg-gray-900 text-white border border-gray-700 focus:ring focus:ring-indigo-500"
                />
              </div>
            </div>
          </form>

          <div class="text-sm text-gray-400">
            Note: This is a placeholder. No actual payment will be processed.
          </div>

          <div>
            <button
              type="button"
              phx-click="submit_payment"
              phx-target={@myself}
              class="bg-white text-black font-semibold px-6 py-3 rounded-md shadow hover:bg-gray-100 transition"
            >
              Pay & Submit
            </button>
          </div>
        </div>
        
    <!-- Review Box -->
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

  def handle_event("update_form", %{"card_number" => _} = _params, socket) do
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
end
