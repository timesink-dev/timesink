defmodule TimesinkWeb.Components.Hero do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents

  def hero(assigns) do
    ~H"""
    <section id="hero-section" class="relative overflow-hidden">
      <div class="w-full flex justify-center">
        <div class="relative flex flex-col md:flex-row w-full max-w-8xl h-[90vh] overflow-hidden">
          <%!-- <!-- Irregular top blend -->
          <div
            class="absolute top-0 left-0 w-full h-8 z-20 pointer-events-none"
            style="background: radial-gradient(ellipse at top left, #0C0C0C 40%, transparent 80%),
                    radial-gradient(ellipse at top right, #0C0C0C 40%, transparent 80%)"
          >
          </div> --%>

          <%!-- <!-- Irregular bottom blend -->
          <div
            class="absolute bottom-0 left-0 w-full h-10 z-30 pointer-events-none"
            style="background:
                  radial-gradient(ellipse 30% 80% at bottom left, #0C0C0C 20%, transparent 60%),
                  radial-gradient(ellipse 30% 80% at bottom right, #0C0C0C 20%, transparent 60%)"
          >
          </div>
           --%>
          <!-- Left image -->
          <div class="relative w-full md:w-2/3 h-[80vh] z-10">
            <img src="/images/hero-17.png" alt="TimeSink Marquee" class="w-full h-full object-cover" />
            <div class="absolute inset-0 z-20 pointer-events-none">
              <div class="absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-[#0C0C0C] to-transparent">
              </div>
              <div class="absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-[#0C0C0C] to-transparent">
              </div>
            </div>
            <%!-- <div class="absolute bottom-0 left-0 w-full h-16 z-20 pointer-events-none bg-gradient-to-t from-[#0C0C0C] via-[#0C0C0C]/70 to-transparent">
            </div> --%>
          </div>
          
    <!-- Right text -->
          <div class="mt-8 lg:mt-0 w-full md:w-1/3 flex items-center justify-center px-6 text-white text-center md:text-left z-10">
            <div class="max-w-md">
              <div class="text-center mb-10">
                <h2 class="text-4xl md:text-5xl font-brand text-white tracking-tight leading-tight">
                  where great films meet great Audiences.
                </h2>
                <p class="mt-4 text-base md:text-lg text-mystery-white max-w-xl mx-auto">
                  Join a friendly broadcast of cinephiles and visionaries exploring bold cinema.
                  Watch live. Connect in real time. Share what moves you.
                </p>
                <a href="/join">
                  <.button class="mt-6 px-6 py-3 font-medium bg-neon-blue-lightest text-backroom-black hover:bg-mystery-white hover:text-black transition">
                    Join the waitlist
                  </.button>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Scroll indicator -->
      <div
        id="scroll-indicator"
        class="fixed bottom-10 inset-x-0 flex justify-center z-50 animate-bounce opacity-80 transition-opacity"
      >
        <span class="text-white text-sm">
          ↓ Scroll to explore cinema
        </span>
      </div>
    </section>
    """
  end
end
