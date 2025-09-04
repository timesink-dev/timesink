defmodule TimesinkWeb.TopNav do
  import TimesinkWeb.CoreComponents, only: [icon: 1, button: 1]
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Timesink.Accounts.User

  attr :class, :string, default: nil
  attr :current_user, User, default: nil

  @spec top_nav(map()) :: Phoenix.LiveView.Rendered.t()
  def top_nav(assigns) do
    ~H"""
    <header class={["z-40 sticky bg-backgroom-black", @class]}>
      <div class="md:hidden flex items-center justify-between border-gray-200 mt-2 text-sm z-40">
        <div class="md:hidden bg-backroom-black font-brand rounded-xl px-2 font-medium leading-6">
          <a id="nav-logo-mobile" href="/" class="font-brand">
            TimeSink Presents
          </a>
        </div>
        <.hamburger_button />
      </div>
      <.open_hamburger current_user={@current_user} />
      <.top_nav_content current_user={@current_user} />
    </header>
    """
  end

  defp top_nav_content(assigns) do
    ~H"""
    <nav class="mt-2" aria-label="Main Navigation">
      <div id="nav-container" class="hidden md:flex justify-between items-center">
        <!-- Main navigation links -->
        <ul id="nav-links" class="flex justify-between items-center gap-x-8">
          <li class="relative hidden md:block">
            <button
              type="button"
              phx-click={JS.toggle(to: "#films-dropdown", display: "block")}
              class="inline-flex items-end gap-1 text-sm font-medium text-mystery-white hover:underline focus:outline-none"
            >
              <span> Cinema </span>
              <.icon name="hero-chevron-down" class="h-4 w-4 mt-[1px] transition-transform" />
            </button>

            <ul
              id="films-dropdown"
              class="hidden absolute mt-2 w-48 rounded-md bg-dark-theater-primary text-mystery-white shadow-md z-50 overflow-hidden"
              phx-click-away={JS.add_class("hidden", to: "#films-dropdown")}
            >
              <li>
                <a href="/now-playing" class="block px-4 py-2 hover:bg-zinc-700">Now Playing</a>
              </li>
              <li>
                <a href="/" class="block px-4 py-2 hover:bg-zinc-700">Upcoming</a>
              </li>
              <li>
                <a href="/archives" class="block px-4 py-2 hover:bg-zinc-700">Archives</a>
              </li>
            </ul>
          </li>

          <li><a href="/blog">Blog</a></li>
          <li><a href="/info">Info</a></li>
        </ul>
        
    <!-- Logo -->
        <div>
          <a id="nav-logo" href="/" class="font-brand">
            TimeSink
          </a>
        </div>
        
    <!-- Actions -->
        <ul id="nav-actions" class="flex justify-between items-center gap-x-8">
          <%= if @current_user do %>
            <!-- Submit link stays as-is -->
    <!-- Account dropdown replaces the Sign Out button -->
            <li class="relative">
              <.button
                id="account-button"
                type="button"
                phx-click={JS.toggle(to: "#account-menu", display: "block")}
                color="none"
                class="inline-flex items-center gap-2 rounded-md px-3 py-1.5 text-sm text-mystery-white hover:bg-zinc-800 focus:outline-none"
                aria-haspopup="menu"
                aria-expanded="false"
              >
                <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-zinc-700 text-[11px] font-semibold">
                  {@current_user.first_name |> String.first() |> String.upcase()}
                </span>
                <span class="hidden lg:inline">Account</span>
              </.button>

              <div
                id="account-menu"
                class="hidden absolute right-0 mt-2 w-48 rounded-md bg-dark-theater-primary text-mystery-white shadow-lg z-50 overflow-hidden"
                phx-click-away={JS.add_class("hidden", to: "#account-menu")}
                role="menu"
                aria-label="Account menu"
              >
                <a href="/me" class="block px-4 py-2 text-sm hover:bg-zinc-700" role="menuitem">
                  Overview
                </a>
                <a
                  href="/me/profile"
                  class="block px-4 py-2 text-sm hover:bg-zinc-700"
                  role="menuitem"
                >
                  Profile
                </a>
                <.form method="post" action="/sign_out" for={%{}} class="border-t border-zinc-700">
                  <button
                    type="submit"
                    class="w-full text-left px-4 py-2 text-sm hover:bg-zinc-700"
                    role="menuitem"
                  >
                    Sign out
                  </button>
                </.form>
              </div>
            </li>
            <li>
              <a href="/submit">
                <.button color="tertiary">
                  Submit film
                </.button>
              </a>
            </li>
          <% else %>
            <li>
              <a href="/sign_in">
                <.button color="tertiary">
                  Sign in
                </.button>
              </a>
            </li>
            <li>
              <a href="/join">
                <.button color="none">Join Waitlist</.button>
              </a>
            </li>
          <% end %>
        </ul>
      </div>
    </nav>
    """
  end

  defp hamburger_button(assigns) do
    ~H"""
    <div class="md:hidden">
      <button
        phx-click={show_hamburger()}
        aria-label="Open menu"
        aria-controls="hamburger-content"
        class="inline-flex items-center justify-center h-12 w-12 rounded-xl
             focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2
            focus-visible:ring-zinc-400 focus-visible:ring-offset-black"
      >
        <.icon name="hero-bars-3" class="h-7 w-7" />
        <span class="sr-only">Open menu</span>
      </button>
    </div>
    """
  end

  defp open_hamburger(assigns) do
    ~H"""
    <div id="hamburger-container" class="hidden relative z-50">
      <div id="hamburger-backdrop" class="fixed inset-0 bg-zinc-900/90 transition-opacity"></div>
      <nav
        id="hamburger-content"
        class="rounded fixed top-0 right-0 bottom-0 flex flex-col grow justify-between w-5/6 md:w-1/2 py-2 bg-backroom-black overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-label="Main menu"
      >
        <div class="mx-6">
          <div class="flex items-center mb-4 place-content-between pb-6 py-2 border-solid border-b-[0.5px] border-dark-theater-primary">
            <div class="flex items-center gap-4">
              <p class="font-brand rounded-xl font-medium leading-6">
                Menu Du Jour
              </p>
            </div>
            <button class="navbar-close" phx-click={hide_hamburger()}>
              <span class="sr-only">Close menu</span>
              <.icon name="hero-x-mark-mini" class="h-6 w-6" />
            </button>
          </div>
          <ul class="flex flex-col justify-start items-start gap-y-4 pt-2.5">
            <li><a href="/now-playing">Now Playing</a></li>
            <li><a href="/archives">Archives</a></li>
            <li><a href="/blog">Blog</a></li>
            <li><a href="/info">Info</a></li>
            <hr />
            <div class="w-full flex flex-col gap-y-4">
              <%= if @current_user do %>
                <!-- Keep mobile actions unchanged for now -->
                <.form method="post" action="/sign_out" for={%{}}>
                  <.button type="submit" color="tertiary" class="w-full md:w-1/2">
                    Sign Out
                  </.button>
                </.form>
                <a href="/submit">
                  <.button color="primary" class="w-full md:w-1/2">
                    Submit film
                  </.button>
                </a>
              <% else %>
                <a href="/sign_in">
                  <.button class="w-full md:w-1/2">
                    Sign in
                  </.button>
                </a>
                <a href="/join">
                  <.button color="tertiary" class="w-full md:w-1/2">
                    Join Waitlist
                  </.button>
                </a>
              <% end %>
            </div>
          </ul>
        </div>
      </nav>
    </div>
    """
  end

  defp show_hamburger(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in-out duration-300", "translate-x-3/4", "translate-x-0"},
      time: 300,
      display: "flex"
    )
    |> JS.show(
      to: "#hamburger-backdrop",
      transition:
        {"transition-all transform ease-in-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#hamburger-container",
      time: 300
    )
    |> JS.add_class("overflow-hidden", to: "body")
  end

  defp hide_hamburger(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#hamburger-backdrop",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in duration-200", "translate-x-0", "translate-x-3/4"}
    )
    |> JS.hide(to: "#hamburger-container", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
  end
end
