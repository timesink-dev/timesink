defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <div class="hero-section">
        <img src="/images/brand-logo.png" alt="Brand Logo" class="logo" />
        <div class="scroll-indicator">
          <span>Scroll to explore cinema</span>
          <div class="arrow-down"></div>
        </div>
      </div>
    </div>
    """
  end
end
