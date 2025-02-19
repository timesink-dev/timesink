defmodule TimesinkWeb.Cinema.ShowcaseLive do
  use TimesinkWeb, :live_view

  on_mount {Timesink.Accounts.Auth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <div id="now-playing">
      <div id="now-playing-section">
        Now Playing
      </div>
    </div>
    """
  end
end
