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

  def mount(_params, _session, socket) do
    # were going to need to get the current_user from the session
    # and then we can get the user from the database
    # and then we can assign the user to the socket
    # so we can render the user's information and allow the user to edit their information
    {:ok, socket}
  end
end
