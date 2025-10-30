# lib/timesink_web/layouts/live_app_layout.ex
defmodule TimesinkWeb.LiveAppLayout do
  use TimesinkWeb, :html
  alias TimesinkWeb.TopNav

  # This function name must match what you pass in the router tuple, e.g. :app
  def app(assigns) do
    ~H"""
    <TopNav.top_nav current_user={@current_user} class="h-[30px] mx-4" />
    <main>
      <div class="min-h-[calc(100vh-60px)]">
        <.flash_group flash={@flash} /> {@inner_content}
      </div>
    </main>
    <footer class="bg-backroom-black text-mystery-white px-12 md:px-0 font-brand py-20 mt-24">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col md:flex-row justify-between gap-12 gap-x-24">
          
    <!-- Column 1: Branding and Contact -->
          <div class="space-y-2.5 md:mx-auto md:text-left">
            <p class="text-xl sm:text-2xl font-semibold">TimeSink Presents</p>
            <p class="text-sm opacity-70">Real time. Real audiences. Real cinema.</p>
            <p class="font-gangster font-light text-xs sm:text-sm">hello@timesinkpresents.com</p>
          </div>
          
    <!-- Column 2: Navigation Links -->
          <div class="space-y-2.5 text-sm md:mx-auto md:text-left">
            <p class="font-semibold text-base mb-2">eXplOre</p>
            <a href="/now-playing" class="hover:underline hover:text-white transition">
              Now Playing
            </a>
            <br />
            <a href="/upcoming" class="hover:underline hover:text-white transition">upcoming</a>
            <br />
            <a href="/archives" class="hover:underline hover:text-white transition">Archives</a>
            <br />
            <a href="/blog" class="hover:underline hover:text-white transition">Blog</a>
            <br />
            <a href="/info" class="hover:underline hover:text-white transition">About</a>
            <br />
          </div>
          
    <!-- Column 3: Participate + Social -->
          <div class="space-y-8 md:space-y-6 text-sm md:mx-auto">
            
    <!-- Participation Section -->
            <div class="space-y-2 md:mx-auto">
              <p class="font-semibold text-base mb-2.5">Make your mark</p>
              <div class="flex flex-col space-y-4">
                <a href="/submit" class="hover:underline hover:text-white transition">
                  <.button color="primary">Submit your film</.button>
                </a>
                <a href="/join" class="hover:underline hover:text-white transition">
                  <.button color="secondary">Get membership</.button>
                </a>
              </div>
            </div>
            
    <!-- Connect Section -->
            <div class="space-y-2 md:mx-auto">
              <p class="font-semibold text-base mb-2">Connect</p>
              <div class="flex space-x-4">
                <a
                  href="https://instagram.com/timesink_"
                  target="_blank"
                  class="hover:underline hover:text-white transition"
                >
                  Instagram
                </a>
                <a
                  href="https://twitter.com/timesink_"
                  target="_blank"
                  class="hover:underline hover:text-white transition"
                >
                  Twitter
                </a>
              </div>
            </div>
            <p class="text-xs opacity-60 mt-12">
              &copy; {DateTime.utc_now().year} TimeSink Presents. All rights reserved.
            </p>
          </div>
        </div>
        
    <!-- Newsletter Signup -->
        <div class="max-w-3xl mx-auto mt-16 border-t border-mystery-white/10 pt-10">
          <p class="text-lg font-semibold mb-2 text-center">
            Get screening updates, op-eds, & Cinematic transmissions from our substack.
          </p>
          <p class="text-sm text-center text-mystery-white/70 mb-2 font-gangster w-2/3 mx-auto">
            Be the first to know about upcoming films, special events, essays, insights, and fresh critique—no noise, just the good stuff.
          </p>
          <div class="flex justify-center mt-6">
            <div class="w-full max-w-md sm:max-w-lg md:max-w-xl lg:max-w-2xl px-4">
              <iframe
                src="https://timesinkpresents.substack.com/embed"
                class="w-full mx-auto block rounded-md"
                style="max-width: 100%; min-height: 150px;"
                height="80"
                frameborder="0"
                scrolling="no"
              >
              </iframe>
            </div>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
