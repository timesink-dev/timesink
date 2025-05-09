defmodule TimesinkWeb.Accounts.ProfileLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts
  import Ecto.Query
  alias Timesink.Accounts
  alias Timesink.Accounts.Profile

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    "@" <> username = profile_username

    with {:ok, [user]} <-
           Accounts.query_users(fn query ->
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
        {Profile.avatar_url(@user.profile.avatar)}
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
