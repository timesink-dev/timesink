defmodule TimesinkWeb.Accounts.ProfileLive do
  use TimesinkWeb, :live_view

  alias Timesink.Account
  import Ecto.Query
  alias Timesink.Account
  alias Timesink.Account.Profile

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    "@" <> username = profile_username

    with {:ok, [user]} <-
           Account.query_users(fn query ->
             query
             |> where([u], ilike(u.username, ^username))
             |> join(:inner, [u], p in Profile, on: p.user_id == u.id)
             |> preload([u, p], profile: [avatar: [:blob]])
           end) do
      {:ok, assign(socket, user: user, profile: user.profile)}

      # TODO: what happens if there's no user/profile for this username?
      # Does it make sense to have an else block here to react this scenario?
      # else
      #   {:ok, []} -> {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div id="profile">
      <div class="profile-section flex flex-col gap-y-2">
        <%= if @user.profile.avatar do %>
          <img
            src={Profile.avatar_url(@user.profile.avatar)}
            alt="Profile picture"
            class="rounded-full w-16 h-16"
          />
        <% else %>
          <span class="inline-flex h-12 w-12 items-center justify-center rounded-full bg-zinc-700 text-lg font-semibold text-mystery-white">
            {@user.first_name |> String.first() |> String.upcase()}
          </span>
        <% end %>
        <div>
          {@user.first_name} {@user.last_name}
        </div>
        <div>
          {@user.username}
        </div>
        <div>
          {@user.email}
        </div>
        <div>
          {@profile.bio}
        </div>
        <div>
          {@profile.location.locality} {@profile.location.country}
        </div>
      </div>
    </div>
    """
  end
end
