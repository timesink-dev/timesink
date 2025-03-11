defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.Utils

  import TimesinkWeb.Accounts.MePageItem

  def render(assigns) do
    ~H"""
    <section id="user">
      <div class="ml-6 mt-8 text-md text-dark-theater-lightest flex flex-col justify-center items-center w-full">
        <span class="mb-2">
          <img
            src={@current_user.profile.avatar_url}
            alt="Profile picture"
            class="rounded-full w-16 h-16"
          />
        </span>
        <span class="leading-4">
          {"@" <> @current_user.username}
        </span>
        <span>
          joined {Utils.format_date(@current_user.inserted_at)}
        </span>
      </div>
      <div class="max-w-2xl mx-auto">
        <.me_page_item
          title="Account"
          items={[
            %{
              title: "Profile",
              icon: "hero-identification",
              link: ~p"/me/profile"
            },
            %{
              title: "Security",
              icon: "hero-lock-closed",
              link: ~p"/me/security"
            }
          ]}
        />
        <.me_page_item
          title="Activity"
          items={[
            %{
              title: "Notifications",
              icon: "hero-bolt",
              coming_soon: true
            },
            %{
              title: "Film submissions",
              icon: "hero-film",
              coming_soon: true
            }
          ]}
        />
        <.me_page_item
          title="Integrations"
          items={[
            %{
              title: "Tips",
              icon: "hero-currency-dollar",
              coming_soon: true
            }
          ]}
        />
      </div>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    user = Timesink.Repo.preload(socket.assigns.current_user, [:profile])
    {:ok, assign(socket, current_user: user)}
  end
end
