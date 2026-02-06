defmodule TimesinkWeb.NewsletterModalComponent do
  use TimesinkWeb, :live_component

  alias TimesinkWeb.NewsletterLive

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="newsletter-modal">
        <div class="space-y-6">
          <div class="border-b border-white/10 pb-5">
            <h2 class="text-xl md:text-2xl font-semibold text-white">
              Get notified
            </h2>
            <p class="mt-2 text-sm text-zinc-400 leading-relaxed">
              One email when the doors open. No spam, no feed, no algorithm.
            </p>
          </div>

          <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 md:p-6">
            <.live_component module={NewsletterLive} id="newsletter-live-modal" variant={:modal} />
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
