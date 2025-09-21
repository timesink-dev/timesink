defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.Utils
  alias Timesink.Account.Profile

  import TimesinkWeb.Accounts.MePageItem

  def mount(_params, _session, socket) do
    user = Timesink.Repo.preload(socket.assigns.current_user, profile: [avatar: [:blob]])

    {:ok, assign(socket, current_user: user)}
  end

  def render(assigns) do
    ~H"""
    <section id="user">
      <div class="ml-6 mt-8 text-sm text-dark-theater-lightest flex flex-col justify-center items-center w-full">
        <span class="mb-2">
          <%= if @current_user.profile.avatar do %>
            <img
              src={Profile.avatar_url(@current_user.profile.avatar)}
              alt="Profile picture"
              class="rounded-full w-16 h-16"
            />
          <% else %>
            <span class="inline-flex h-12 w-12 items-center justify-center rounded-full bg-zinc-700 text-lg font-semibold text-mystery-white">
              {@current_user.first_name |> String.first() |> String.upcase()}
            </span>
          <% end %>
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
              link: ~p"/me/film-submissions"
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
end
