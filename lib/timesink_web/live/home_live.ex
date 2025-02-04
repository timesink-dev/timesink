defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  on_mount {Timesink.Accounts.Auth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <div id="hero-section">
        <div id="scroll-indicator">
          <span>Scroll to explore cinema</span>
        </div>
      </div>
    </div>
    """
  end
end
