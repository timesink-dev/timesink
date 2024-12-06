defmodule TimesinkWeb.Accounts.UserLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user">
      <div class="user-section">
        hello
      </div>
    </div>
    """
  end
end
