defmodule TimesinkWeb.Accounts.ProfileLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts

  def render(assigns) do
    ~H"""
    <div id="profile">
      <div class="profile-section">
        <%= @profile.first_name %> <%= @profile.last_name %>
        <%= @profile.username %>
        <%= @profile.email %>
      </div>
    </div>
    """
  end

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    profile_user =
      Accounts.get_user_by!(username: profile_username)

    {:ok, assign(socket, profile: profile_user)}
  end

  # def handle_params(params, _url, socket) do
  #   {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  # end
end
