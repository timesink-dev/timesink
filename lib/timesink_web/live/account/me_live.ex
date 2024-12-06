defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user">
      <div class="user-section">
        Me
      </div>
    </div>
    """
  end
end
