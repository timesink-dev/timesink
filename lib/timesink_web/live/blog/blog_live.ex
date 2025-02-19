defmodule TimesinkWeb.BlogLive do
  use TimesinkWeb, :live_view

  on_mount {Timesink.Accounts.Auth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <section>
      Blog
    </section>
    """
  end
end
