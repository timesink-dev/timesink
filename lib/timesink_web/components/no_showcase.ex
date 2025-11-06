defmodule TimesinkWeb.Components.NoShowcase do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents

  @doc """
  Renders the "no active showcase" view with feature highlights and CTAs.
  """
  attr :class, :string, default: nil, doc: "Additional CSS classes"

  def no_showcase(assigns) do
    ~H"""
    <section class={[
      "text-white my-8 px-6 max-w-3xl md:max-w-4xl mx-auto min-h-[80vh] flex items-center",
      @class
    ]}>
      <div class="w-full text-center">
        <div
          class="mx-auto mb-4 h-9 w-9 rounded-full bg-zinc-900 ring-1 ring-zinc-800 flex items-center justify-center text-zinc-300"
          aria-hidden="true"
        >
          📌
        </div>

        <h1 class="text-2xl font-semibold tracking-tight mb-3">
          We're working on picking the first showcase...
        </h1>
        <p class="text-zinc-400 text-balance max-w-2xl mx-auto">
          TimeSink is a live, curated cinema. When there isn't an active release, we're busy selecting the next one. Keep checking back soon.
        </p>
        
    <!-- Feature highlights -->
        <div class="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left flex flex-col min-h-[104px]">
            <div class="order-2 sm:order-1 mb-0 sm:mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
              <.icon name="hero-video-camera" class="h-4 w-4 text-neon-blue-lightest" />
            </div>
            <div class="order-1 sm:order-2 text-sm text-zinc-300 mb-3 sm:mb-0">
              All levels of filmmakers welcome
            </div>
          </div>

          <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left flex flex-col min-h-[104px]">
            <div class="order-2 sm:order-1 mb-0 sm:mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
              <.icon name="hero-chat-bubble-left-right" class="h-4 w-4 text-neon-blue-lightest" />
            </div>
            <div class="order-1 sm:order-2 text-sm text-zinc-300 mb-3 sm:mb-0">
              Watch together with a live audience
            </div>
          </div>

          <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left flex flex-col min-h-[104px]">
            <div class="order-2 sm:order-1 mb-0 sm:mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
              <.icon name="hero-play" class="h-4 w-4 text-neon-blue-lightest" />
            </div>
            <div class="order-1 sm:order-2 text-sm text-zinc-300 mb-3 sm:mb-0">
              Live showtimes every 30 minutes
            </div>
          </div>

          <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left flex flex-col min-h-[104px]">
            <div class="order-2 sm:order-1 mb-0 sm:mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
              <.icon name="hero-sparkles" class="h-4 w-4 text-neon-blue-lightest" />
            </div>
            <div class="order-1 sm:order-2 text-sm text-zinc-300 mb-3 sm:mb-0">
              Retrospectives, premieres, hidden gems
            </div>
          </div>
        </div>
        
    <!-- CTAs -->
        <p class="my-3 mt-12 text-zinc-400 text-balance max-w-2xl mx-auto">
          📣 Submissions are open — if you’ve made a film or know someone who has, spread the word and send it our way.
        </p>
        <div class="mt-8 flex flex-col sm:flex-row items-stretch sm:items-center justify-center gap-3">
          <.link
            navigate="/submit"
            class="inline-flex justify-center items-center gap-2 rounded-xl border border-white/15 bg-white/[0.06] px-4 py-2 text-sm text-white hover:bg-white/[0.10] transition w-full sm:w-auto"
            aria-label="Submit your film"
          >
            <.icon name="hero-arrow-up-tray" class="h-4 w-4" /> Submit your film
          </.link>
          <.link
            navigate="/info"
            class="inline-flex justify-center items-center gap-2 rounded-xl border border-white/10 px-4 py-2 text-sm text-zinc-300 hover:bg-white/[0.06] transition w-full sm:w-auto"
            aria-label="Learn how programming works"
          >
            <.icon name="hero-information-circle" class="h-4 w-4" /> How programming works
          </.link>
        </div>

        <p class="mt-6 text-sm text-zinc-500">
          Questions? <span>contact hello@timesinkpresents.com</span>
        </p>
      </div>
    </section>
    """
  end
end
