defmodule TimesinkWeb.Components.Hero do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents

  attr :spots_left, :integer, default: nil

  def hero(assigns) do
    ~H"""
    <section
      id="hero-section"
      class="relative h-screen w-full bg-[#0C0C0C] text-white overflow-hidden"
    >
      <!-- md+: 5/2 split; mobile: stacked (no gap) -->
      <div class="sm:grid h-full w-full gap-0 md:grid-cols-[5fr_2fr]">
        <!-- LEFT: poster (flush-left). On md+ we nudge it left & slightly scale for a nicer crop -->
        <div class="relative h-[50vh] md:h-full">
          <img
            src="/images/timesink_hero.webp"
            alt="TimeSink Presents — night marquee"
            width="2880"
            height="1620"
            class="
              absolute inset-0 h-full w-full object-cover object-[center_45%]
              md:transform-gpu  md:translate-x-[-2%]
               lg:translate-x-[-2%]
               xl:translate-x-[-4%]
            "
            loading="eager"
            decoding="async"
          />
        </div>
        
    <!-- RIGHT: compact, centered text panel -->
        <div class="lg:translate-x-[-20%] relative flex items-center justify-center
          px-6 pt-3 pb-[max(env(safe-area-inset-bottom),0.75rem)]
          md:px-8 md:py-0
          bg-transparent md:bg-[#0C0C0C]/88 md:backdrop-blur-sm
        ">
          <div class="w-full max-w-[24rem] text-center">
            <h2 class="font-brand text-3xl md:text-4xl tracking-tight">
              Fresh Cinema selected for you. Real Audiences. No endless scrolls.
            </h2>

            <p class="mt-3 text-mystery-white">
              We bring great filmmakers — of all levels — to the stage.
              And we don’t waste your time discovering them. Real audiences. Real-time reactions.
              Conversations and moments that last. No noise — pure signal.
            </p>

            <a href="/join" class="block">
              <.button class="mt-5 justify-center px-6 py-2 md:py-2.5 font-medium bg-neon-blue-lightest text-backroom-black hover:bg-mystery-white hover:text-black transition">
                Get started
              </.button>
            </a>
          </div>
        </div>
      </div>
      
    <!-- Scroll cue (desktop only) -->
      <div
        id="scroll-indicator"
        class="hidden md:flex fixed bottom-8 inset-x-0 justify-center z-20 motion-safe:animate-bounce opacity-80"
      >
        <span class="text-white text-sm">↓ Scroll to explore cinema</span>
      </div>
    </section>
    """
  end
end
