defmodule TimesinkWeb.LiveAppLayout do
  use TimesinkWeb, :html
  alias TimesinkWeb.TopNav
  alias TimesinkWeb.NewsletterLive

  # This function name must match what you pass in the router tuple, e.g. :app
  def app(assigns) do
    ~H"""
    <TopNav.top_nav current_user={@current_user} class="h-[30px] mx-4" />
    <main>
      <div class="min-h-[calc(100vh-60px)]">
        <Toast.toast_group
          flash={@flash}
          position="bottom-center"
          theme="dark"
          rich_colors={false}
          max_toasts={4}
            animation_duration={400}
            duration={3000}

        />
        {@inner_content}
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
          <div class="space-y-2 text-md md:mx-auto md:text-left">
            <p class="font-semibold text-lg mb-2">eXplOre</p>
            <div class="flex flex-col gap-y-2">
              <a href="/now-playing" class="hover:underline hover:text-white transition">
                Now Playing
              </a>
              <a href="/upcoming" class="hover:underline hover:text-white transition">upcoming</a>
              <a href="/archives" class="hover:underline hover:text-white transition">Archives</a>
              <a href="/blog" class="hover:underline hover:text-white transition">Blog</a>
              <a href="/info" class="hover:underline hover:text-white transition">About</a>
            </div>
            <br />
          </div>

    <!-- Column 3: Participate + Social -->
          <div class="space-y-8 md:space-y-6 text-sm md:mx-auto">

    <!-- Participation Section -->
            <div class="space-y-2 md:mx-auto">
              <p class="font-semibold text-lg mb-4">Make your mark</p>
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
              <p class="font-semibold text-lg mb-2">Connect</p>
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
        <.live_component module={NewsletterLive} id="newsletter-footer" />
      </div>
    </footer>
    """
  end
end
