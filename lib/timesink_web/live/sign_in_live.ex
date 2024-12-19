defmodule TimesinkWeb.SignInLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div id="sign-in">
      <div id="sign-in-section">
        Sign In
      </div>
    </div>
    """
  end
end
