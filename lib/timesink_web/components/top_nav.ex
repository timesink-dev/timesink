defmodule TimesinkWeb.TopNav do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents, only: [icon: 1, button: 1]
  alias Phoenix.LiveView.JS
  alias Timesink.UserCache
  alias Timesink.Account.Profile
  alias Timesink.Storage.Attachment
  alias Ecto.Association.NotLoaded

  attr :class, :string, default: nil
  attr :current_user, :any, default: nil
  # allow parent/root LV to seed an avatar_url (so no flicker)
  attr :avatar_url, :string, default: nil

  def top_nav(assigns) do
    ~H"""
    <header class={["z-40 sticky bg-backgroom-black", @class]}>
      <div class="md:hidden flex items-center justify-between border-gray-200 mt-2 text-sm z-40">
        <div class="md:hidden bg-backroom-black font-brand rounded-xl px-2 font-medium leading-6">
          <a id="nav-logo-mobile" href="/" class="font-brand mobile-logo">
            <svg xmlns="http://www.w3.org/2000/svg" width="122" height="12" fill="none">
              <path
                fill="#F5F7F9"
                d="M10.508.5v.98h-4.69V11h-1.12V1.48H.008V.5h10.5Zm3.082 0V11h-1.12V.5h1.12Zm7.493-.196V11h-1.12V4.392L18.465 7.22l-1.512-2.828V11h-1.12V.304l2.632 4.76 2.618-4.76Zm7.492 9.716V11h-5.25V.5h5.25v.98h-4.13v3.78h4.13v.98h-4.13v3.78h4.13Zm11.587-1.736c0 2.184-2.45 3.066-4.564 3.066-2.478 0-4.48-.882-5.768-3.052l.84-.532c1.092 1.848 2.8 2.632 4.928 2.632s3.486-.966 3.486-2.114c0-3.304-8.624-.602-8.624-5.068 0-2.114 2.296-3.01 4.284-3.01 2.338 0 4.116.756 5.208 2.8l-.84.504c-.938-1.736-2.38-2.366-4.354-2.366-1.96 0-3.22.966-3.22 2.072 0 3.234 8.624.574 8.624 5.068ZM43.45.5V11h-1.12V.5h1.12Zm7.493 0v10.696l-4.13-7.028V11h-1.12V.304l4.13 7.028V.5h1.12Zm4.65 5.25 2.87 5.25h-1.288l-2.87-5.25L57.174.5h1.288l-2.87 5.25ZM54.305.5V11h-1.12V.5h1.12Zm18.718 2.87a2.874 2.874 0 0 1-2.87 2.87h-6.51V11h-1.12V.5h7.63a2.874 2.874 0 0 1 2.87 2.87Zm-1.12 0c0-1.05-.7-1.89-1.75-1.89h-6.51v3.78h6.51c1.05 0 1.75-.84 1.75-1.89Zm5.462 2.856L79.982 11h-1.288l-2.87-5.25V11h-1.12V.5h2.38a2.874 2.874 0 0 1 2.87 2.87 2.872 2.872 0 0 1-2.59 2.856Zm1.47-2.856c0-1.05-.7-1.89-1.75-1.89h-1.26v3.78h1.26c1.05 0 1.75-.84 1.75-1.89Zm8.352 6.65V11h-5.25V.5h5.25v.98h-4.13v3.78h4.13v.98h-4.13v3.78h4.13Zm6.66-1.484c0 1.442-.939 2.744-2.618 2.744-1.316 0-2.646-.952-2.646-2.87h1.12c0 1.26.755 1.89 1.511 1.89.91 0 1.513-.882 1.513-1.82 0-.728-.35-1.484-1.19-1.932l-1.064-.574a3.52 3.52 0 0 1-1.876-3.094c0-1.386.882-2.66 2.59-2.66 1.315 0 2.645.924 2.645 2.744h-1.12c0-1.176-.755-1.764-1.511-1.764-.966 0-1.484.812-1.484 1.708 0 .77.364 1.582 1.148 2.002l1.078.56c1.302.7 1.904 1.932 1.904 3.066Zm6.917 1.484V11h-5.25V.5h5.25v.98h-4.13v3.78h4.13v.98h-4.13v3.78h4.13ZM107.968.5v10.696l-4.13-7.028V11h-1.12V.304l4.13 7.028V.5h1.12Zm6.932 0v.98h-2.058V11h-1.12V1.48h-2.072V.5h5.25Zm6.385 8.036c0 1.442-.938 2.744-2.618 2.744-1.316 0-2.646-.952-2.646-2.87h1.12c0 1.26.756 1.89 1.512 1.89.91 0 1.512-.882 1.512-1.82 0-.728-.35-1.484-1.19-1.932l-1.064-.574a3.52 3.52 0 0 1-1.876-3.094c0-1.386.882-2.66 2.59-2.66 1.316 0 2.646.924 2.646 2.744h-1.12c0-1.176-.756-1.764-1.512-1.764-.966 0-1.484.812-1.484 1.708 0 .77.364 1.582 1.148 2.002l1.078.56c1.302.7 1.904 1.932 1.904 3.066Z"
              />
            </svg>
          </a>
        </div>
        <.hamburger_button />
      </div>
      <.open_hamburger current_user={@current_user} />
      <.top_nav_content current_user={@current_user} />
    </header>
    """
  end

  attr :current_user, :any, default: nil
  attr :avatar_url, :string, default: nil

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
          <a id="nav-logo" href="/" class="font-brand logo-primary">
            <svg xmlns="http://www.w3.org/2000/svg" width="67" height="14" fill="none">
              <path
                fill="#F5F7F9"
                d="M12 1v1.12H6.64V13H5.36V2.12H0V1h12Zm3.52 0v12h-1.28V1h1.28Zm8.565-.224V13h-1.28V5.448L21.093 8.68l-1.728-3.232V13h-1.28V.776l3.008 5.44 2.992-5.44Zm8.562 11.104V13h-6V1h6v1.12h-4.72v4.32h4.72v1.12h-4.72v4.32h4.72ZM45.89 9.896c0 2.496-2.8 3.504-5.216 3.504-2.832 0-5.12-1.008-6.592-3.488l.96-.608c1.248 2.112 3.2 3.008 5.632 3.008 2.432 0 3.984-1.104 3.984-2.416 0-3.776-9.856-.688-9.856-5.792 0-2.416 2.624-3.44 4.896-3.44 2.672 0 4.704.864 5.952 3.2l-.96.576c-1.072-1.984-2.72-2.704-4.976-2.704-2.24 0-3.68 1.104-3.68 2.368 0 3.696 9.856.656 9.856 5.792ZM49.646 1v12h-1.28V1h1.28Zm8.564 0v12.224l-4.72-8.032V13h-1.28V.776l4.72 8.032V1h1.28Zm5.314 6 3.28 6h-1.472l-3.28-6 3.28-6h1.472l-3.28 6Zm-1.472-6v12h-1.28V1h1.28Z"
              />
            </svg>
          </a>
        </div>

        <ul id="nav-actions" class="flex justify-between items-center gap-x-8">
          <%= if @current_user do %>
            <li class="relative">
              <.button
                id="account-button"
                type="button"
                phx-click={JS.toggle(to: "#account-menu", display: "block")}
                color="none"
                class="inline-flex items-center gap-2 rounded-md px-3 py-1.5 text-sm text-mystery-white focus:outline-none"
                aria-haspopup="menu"
                aria-expanded="false"
              >
                <%!-- # 1) prefer injected avatar_url from parent (no flicker)
                # 2) cache by current user id
                # 3) compute from preloaded structs if present
                 --%>
                <% resolved_url =
                  (@avatar_url && String.trim(@avatar_url) != "" && @avatar_url) ||
                    (@current_user.id && UserCache.get_avatar_url(@current_user.id)) ||
                    avatar_url_or_nil(@current_user) %>

                <%= if resolved_url do %>
                  <.live_component
                    module={TimesinkWeb.NavAvatarLive}
                    id={"nav-avatar-#{@current_user.id}"}
                    user_id={@current_user.id}
                    avatar_url={resolved_url}
                  />
                <% else %>
                  <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-zinc-700 text-[11px] font-semibold">
                    {initials(@current_user)}
                  </span>
                <% end %>
              </.button>

              <div
                id="account-menu"
                class="hidden absolute right-0 mt-2 w-48 rounded-md bg-dark-theater-primary text-mystery-white shadow-lg z-50 overflow-hidden"
                phx-click-away={JS.add_class("hidden", to: "#account-menu")}
                role="menu"
                aria-label="Account menu"
              >
                <a
                  href="/me/profile"
                  class="block px-4 py-2 text-sm hover:bg-zinc-700"
                  role="menuitem"
                >
                  View profile
                </a>
                <a href="/me" class="block px-4 py-2 text-sm hover:bg-zinc-700" role="menuitem">
                  Account
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
                <.button color="tertiary">Submit film</.button>
              </a>
            </li>
          <% else %>
            <li>
              <a href="/sign-in">
                <.button color="tertiary">Sign in</.button>
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
                <a href="/sign-in">
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

  defp initials(%{first_name: fnm, last_name: lnm}) do
    f = fnm |> to_string() |> String.trim() |> String.first() || ""
    l = lnm |> to_string() |> String.trim() |> String.first() || ""

    case String.upcase(f <> l) do
      "" -> "?"
      s -> s
    end
  end

  # Try current_user.profile first (if preloaded). Otherwise nil.
  defp avatar_url_or_nil(%{profile: %NotLoaded{}}), do: nil
  defp avatar_url_or_nil(%{profile: nil}), do: nil

  defp avatar_url_or_nil(%{profile: %{avatar: %Attachment{} = att}}),
    do: Profile.avatar_url(att, :md)

  defp avatar_url_or_nil(_), do: nil
end
