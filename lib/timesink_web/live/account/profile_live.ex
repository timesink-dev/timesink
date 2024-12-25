defmodule TimesinkWeb.Accounts.ProfileLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts
  import Ecto.Query
  alias Timesink.Accounts
  alias Timesink.Accounts.Profile

  def render(assigns) do
    ~H"""
    <div id="profile">
      <div class="profile-section flex flex-col gap-y-2">
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

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    with {:ok, [user]} <-
           Accounts.query_users(fn query ->
             query
             |> where([u], u.username == ^profile_username)
             |> join(:inner, [u], p in Profile, on: p.user_id == u.id)
             |> preload([u, p], profile: p)
           end) do
      {:ok, assign(socket, user: user, profile: user.profile)}

      # TODO: what happens if there's no user/profile for this username?
      # Does it make sense to have an else block here to react this scenario?
      # else
      #   {:ok, []} -> {:ok, socket}
    end
  end
end
