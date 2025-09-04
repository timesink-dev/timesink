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
          <div class="relative w-full md:w-2/3 min-h-[40vh] md:h-[75vh] z-10">
            <picture>
              <%!--
                Provide a mobile-specific crop if available (recommended), otherwise the browser
                will still render the <img> fallback.
              --%>
              <source srcset="/images/hero-minified.webp" media="(max-width: 767px)" />
              <img
                src="/images/hero-minified.webp"
                alt="TimeSink marquee with a cinematic glow"
                class="w-full h-full
                       object-contain md:object-cover
                       object-center md:object-[50%_50%]"
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
      <section id="bridge" class="relative isolate">
        <!-- subtle top divider glow -->
        <div class="pointer-events-none absolute inset-x-0 -top-4 h-8 bg-gradient-to-b from-black/30 to-transparent">
        </div>

        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12 md:py-16">
          <!-- value proposition -->
          <div class="text-center mb-10">
            <h2 class="text-2xl md:text-3xl font-semibold tracking-tight">
              A virtual arthouse cinema—curated films, real-time conversation.
            </h2>
            <p class="mt-3 text-balance text-base md:text-lg text-zinc-400">
              Watch together. Chat live. Discover voices you won’t find on the multiplex billboard.
            </p>

            <%= if @spots_left do %>
              <p class="mt-4 inline-flex items-center gap-2 rounded-full border border-emerald-500/40 bg-emerald-500/10 px-3 py-1 text-sm text-emerald-300">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M12 2a10 10 0 1 1 0 20A10 10 0 0 1 12 2Zm1 5h-2v6l5 3 .9-1.79L13 12.5V7Z" />
                </svg>
                Only {@spots_left} spots left in this wave
              </p>
            <% end %>
          </div>
          
    <!-- 3 column highlights -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
                <!-- film icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M4 4h4v4H4V4Zm6 0h4v4h-4V4Zm6 0h4v4h-4V4ZM4 10h16v10H4V10Zm0 6h4v4H4v-4Zm12 0h4v4h-4v-4Z" />
                </svg>
              </div>
              <h3 class="text-lg font-medium">Curated indie lineup</h3>
              <p class="mt-1 text-sm text-zinc-400">
                Spotlight on festival favorites, hidden gems, and filmmaker premieres.
              </p>
            </div>

            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
                <!-- chat icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2Z" />
                </svg>
              </div>
              <h3 class="text-lg font-medium">Live chat that feels alive</h3>
              <p class="mt-1 text-sm text-zinc-400">
                Lean-in conversations with cinephiles, not noisy comment walls.
              </p>
            </div>

            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
                <!-- globe icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm6.93 6h-3.26a14.6 14.6 0 0 0-2.01-4.2A8.03 8.03 0 0 1 18.93 8ZM12 4.06c.9 1.17 1.67 2.67 2.2 3.94H9.8c.53-1.27 1.3-2.77 2.2-3.94ZM5.07 8h3.26c.34-1.02.8-2.07 1.34-3.02A8.03 8.03 0 0 0 5.07 8Zm0 8a8.03 8.03 0 0 1 4.6 3.02A14.6 14.6 0 0 1 8.33 16H5.07Zm4.73 0h4.4c-.53 1.27-1.3 2.77-2.2 3.94-.9-1.17-1.67-2.67-2.2-3.94Zm8.13 0h-3.26c-.34 1.02-.8 2.07-1.34 3.02A8.03 8.03 0 0 0 17.93 16Zm-1.6-6c.27.96.45 2 .5 3.05H7.17c.05-1.05.23-2.09.5-3.05h8.66Z" />
                </svg>
              </div>
              <h3 class="text-lg font-medium">Global community</h3>
              <p class="mt-1 text-sm text-zinc-400">
                Join screenings with viewers from everywhere—discover, discuss, repeat.
              </p>
            </div>
          </div>
          
    <!-- slim schedule teaser -->
          <div class="mt-10 rounded-2xl border border-white/10 bg-gradient-to-r from-white/[0.03] to-white/[0.01] p-5">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <p class="text-sm uppercase tracking-wider text-zinc-400">This week</p>
                <h4 class="mt-1 text-lg font-medium">Upcoming screenings &amp; special events</h4>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <div class="inline-flex items-center gap-2 rounded-full bg-white/[0.06] px-3 py-1">
                  <div class="h-2 w-2 rounded-full animate-pulse bg-current"></div>
                  Live showings every 30 minutes
                </div>
                <a
                  href="/now"
                  class="rounded-full border border-white/15 px-3 py-1 hover:bg-white/[0.06]"
                >
                  View schedule
                </a>
              </div>
            </div>
            
    <!-- pills-style items; replace with dynamic events later -->
            <div class="mt-4 flex flex-wrap gap-2">
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Thu 20:00 — Director Q&A
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Sat 18:30 — Shorts Block: New Voices
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Sun 21:15 — Midnight Cult Classic
              </span>
            </div>
          </div>
        </div>
      </section>
    </section>
    """
  end
end
