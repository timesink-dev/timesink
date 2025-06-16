defmodule TimesinkWeb.FilmSubmission.StepConfirmationComponent do
  use TimesinkWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-3xl mx-auto text-center space-y-10">
        <!-- Success Icon -->
        <div class="mx-auto w-20 h-20 rounded-full bg-green-600/10 border border-green-600 flex items-center justify-center">
          <svg
            class="w-10 h-10 text-green-400"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            viewBox="0 0 24 24"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
    <!-- Headline -->
        <div>
          <h2 class="text-3xl font-brand text-white">Your film has been submitted!</h2>
          <p class="mt-2 text-gray-300 text-lg">
            We’ve received your submission and sent a confirmation email to <span class="text-white font-semibold">"your email"</span>.
          </p>
        </div>

        <div class="bg-orange-400/2 border-[1px] border-orange-500 rounded-lg px-6 py-5 text-left relative overflow-hidden">
          <div class="space-y-2 text-sm text-amber-100">
            <div class="flex justify-between items-center">
              <span class="font-semibold text-white">Film Title</span>
              <span>{@data.title || "Untitled Masterpiece"}</span>
            </div>
            <div class="flex justify-between items-start gap-4">
              <span class="font-semibold text-white">Synopsis</span>
              <span class="text-right">{@data.synopsis || "No synopsis provided."}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="font-semibold text-white">Private Video Link</span>
              <span>{@data.video_url || "Not provided"}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="font-semibold text-white">Payment Ref</span>
              <span>{@data.payment_id || "Pending"}</span>
            </div>
          </div>
        </div>
        
    <!-- Next Steps -->
        <div class="text-gray-400 text-sm">
          Our programming team reviews every submission with care. If your work is selected, we’ll reach out with next steps.
        </div>
        
    <!-- Optional Share or CTA -->
        <div class="mt-6">
          <a
            href="/"
            class="inline-block bg-white text-black font-semibold px-6 py-2 rounded hover:bg-gray-100 transition"
          >
            Return to Homepage
          </a>
        </div>
      </div>
    </section>
    """
  end
end
