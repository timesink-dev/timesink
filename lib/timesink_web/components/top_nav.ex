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
        <p class="md:hidden bg-backroom-black font-brand rounded-xl px-2 font-medium leading-6">
          TimeSink Presents
        </p>
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
          <li><a href="/now-playing">Now Playing</a></li>
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
            <.form method="post" action="/sign_out" for={}>
              <.button type="submit" color="tertiary" class="text-mystery-white">
                Sign Out
              </.button>
            </.form>
            <li><a href="/submit">Submit film</a></li>
          <% else %>
            <li><a href="/sign_in">Sign in</a></li>
            <li><a href="/join">Join Waitlist</a></li>
          <% end %>
        </ul>
      </div>
    </nav>
    """
  end

  defp hamburger_button(assigns) do
    ~H"""
    <div class="md:hidden">
      <button phx-click={show_hamburger()}>
        <.icon name="hero-bars-3" />
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
      >
        <div class="mx-6">
          <div class="flex items-center mb-4 place-content-between pb-6 py-2 border-solid border-b-[0.5px] border-dark-theater-primary">
            <div class="flex items-center gap-4">
              <p class="font-brand rounded-xl font-medium leading-6">
                Menu Du Jour
              </p>
            </div>
            <button class="navbar-close" phx-click={hide_hamburger()}>
              <.icon name="hero-x-mark-mini" />
            </button>
          </div>
          <ul class="flex flex-col justify-start items-start gap-y-4 pt-2.5">
            <li><a href="/now-playing">Now Playing</a></li>
            <li><a href="/blog">Blog</a></li>
            <li><a href="/info">Info</a></li>
            <hr />
            <div class="w-full flex flex-col gap-y-4">
              <%= if @current_user do %>
                <.form method="post" action="/sign_out" for={}>
                  <.button type="submit" color="tertiary" class="w-full md:w-1/2">
                    Sign Out
                  </.button>
                </.form>
                <.button color="primary" class="w-full md:w-1/2">
                  Submit film
                </.button>
              <% else %>
                <a href="/sign_in">
                  <.button class="w-full md:w-1/2">
                    Sign In
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
