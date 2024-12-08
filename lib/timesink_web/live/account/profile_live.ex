defmodule TimesinkWeb.Accounts.ProfileLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts

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
    {:ok, %{user: user, profile: profile}} =
      Accounts.get_profile_by_username!(username: profile_username)

    {:ok, assign(socket, user: user, profile: profile)}
  end
end
