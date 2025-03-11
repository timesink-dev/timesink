defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
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
