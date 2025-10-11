defmodule TimesinkWeb.Components.Hero do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents

  attr :spots_left, :integer, default: nil

  def hero(assigns) do
    ~H"""
    <section id="hero-section" class="relative overflow-hidden">
      <div class="w-full flex justify-center">
        <!-- Mobile: auto height; Desktop: controlled viewport height (original feel) -->
        <div class="relative flex flex-col md:flex-row w-full max-w-8xl
                    md:h-[80vh] lg:h-[85vh]
                    overflow-hidden">
          <%!-- Irregular bottom blend (optional) --%>
          <div
            class="absolute bottom-0 left-0 w-full h-10 z-30 pointer-events-none"
            style="background:
                  radial-gradient(ellipse 30% 80% at bottom left, #0C0C0C 20%, transparent 60%),
                  radial-gradient(ellipse 30% 80% at bottom right, #0C0C0C 20%, transparent 60%)"
          >
          </div>
          
    <!-- Left image -->
          <div class="relative w-full md:w-2/3 min-h-[40vh] md:h-[95vh] z-10">
            <picture>
              <%!--
                Provide a mobile-specific crop if available (recommended), otherwise the browser
                will still render the <img> fallback.
              --%>
              <source srcset="/images/hero_asset.webp" media="(max-width: 767px)" />
              <img
                src="/images/hero_asset_2.jpeg"
                alt="TimeSink marquee with a cinematic glow"
                class="w-full h-full
                       object-contain md:object-cover
                       object-center md:object-[80%_70%]"
                loading="eager"
                fetchpriority="high"
                width="1920"
                height="1080"
              />
            </picture>

            <div class="absolute inset-0 z-20 pointer-events-none">
              <div class="absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-[#0C0C0C] to-transparent">
              </div>
              <div class="absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-[#0C0C0C] to-transparent">
              </div>
            </div>
          </div>
          
    <!-- Right text -->
          <div class="mt-6 md:mt-0 w-full md:w-1/3 flex items-center justify-center
                      px-6 pb-[max(env(safe-area-inset-bottom),1rem)]
                      text-white text-center md:text-left z-10">
            <div class="max-w-md">
              <div class="text-center mb-10">
                <h2 class="text-3xl md:text-4xl font-brand text-white tracking-tight leading-tight">
                  Fresh Cinema selected for you. Real Audiences. No endless scrolls.
                </h2>

                <p class="mt-4 text-[15px] md:text-md text-mystery-white max-w-prose md:max-w-xl mx-auto">
                  We bring great filmmakers — of all levels — to the stage.
                  And we don’t waste your time discovering them. Real audiences. Real-time reactions. Conversations and moments that last.
                  No noise — pure signal.
                </p>

                <a href="/join">
                  <.button class="mt-6 h-12 px-6 text-base font-medium hover:bg-mystery-white hover:text-black transition">
                    Get started
                  </.button>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Scroll indicator: desktop only to avoid safe-area conflicts on mobile -->
      <div
        id="scroll-indicator"
        class="hidden md:flex fixed bottom-10 inset-x-0 justify-center z-50 motion-safe:animate-bounce opacity-80"
      >
        <span class="text-white text-sm">
          ↓ Scroll to explore cinema
        </span>
      </div>
    </section>
    """
  end
end
