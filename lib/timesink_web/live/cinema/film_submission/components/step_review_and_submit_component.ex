defmodule TimesinkWeb.FilmSubmission.StepReviewAndSubmitComponent do
  use TimesinkWeb, :live_component

  import TimesinkWeb.CoreComponents, only: [button: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-3xl mx-auto space-y-12">
        <!-- Header -->
        <div>
          <h2 class="text-3xl font-brand">Review & Submit</h2>
          <p class="text-gray-300 mt-2">
            Here's what you're submitting. Take a moment to review everything before finalizing.
          </p>
        </div>
        
    <!-- Review Details -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 text-sm text-gray-100">
          <!-- Contact Info -->
          <div class="space-y-2">
            <h3 class="font-semibold text-lg text-white">Your Info</h3>
            <div><strong>Name:</strong> {@data.contact_name || "No name provided"}</div>
            <div><strong>Email:</strong> {@data.contact_email || "No email provided"}</div>
          </div>
          
    <!-- Film Info -->
          <div class="space-y-2">
            <h3 class="font-semibold text-lg text-white">Film Details</h3>
            <div><strong>Title:</strong> {@data.title || "No title provided"}</div>
            <div><strong>Synopsis:</strong> {@data.synopsis || "No synopsis provided"}</div>
            <div><strong>Video URL:</strong> {@data.video_url || "No video URL provided"}</div>
            <%= if @data.video_pw != "" do %>
              <div><strong>Password:</strong> {@data.video_pw || "No password provided"}</div>
            <% end %>
          </div>
          
    <!-- Payment Confirmation -->
          <div class="md:col-span-2 bg-gray-900/60 border border-gray-700 p-4 rounded-md mt-4">
            <div class="flex items-center justify-between">
              <div class="text-white font-medium">Submission Fee</div>
              <div class="text-green-400 font-bold">$25.00 – Paid</div>
            </div>
            <div class="mt-2 text-xs text-gray-400">
              Payment ID: {@data.payment_id || "Not available"}<br />
              Your payment has been securely processed.
            </div>
          </div>
        </div>
        
    <!-- Submit Button -->
        <div class="pt-8 border-t border-gray-800">
          <.button phx-click="final_submit" phx-target={@myself} class="w-full md:w-auto">
            Submit My Film
          </.button>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("final_submit", _params, socket) do
    # Trigger final processing here or broadcast to parent
    send(self(), {:final_submit, %{params: socket.assigns.data}})
    {:noreply, socket}
  end
end
