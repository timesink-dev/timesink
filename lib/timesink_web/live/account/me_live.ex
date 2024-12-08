defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user">
      <div class="user-section">
        {@user.username}
        {@profile.bio}
        {@profile.location.locality}
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    case Timesink.Accounts.get_me() do
      {:ok, %{user: user, profile: profile}} ->
        {:ok, assign(socket, user: user, profile: profile)}

      {:error, _} ->
        {:error, socket}
    end
  end
end
