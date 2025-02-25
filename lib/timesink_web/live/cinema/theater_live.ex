defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="theater">
      <div id="theater-section">
        Theater
      </div>
    </div>
    """
  end

  def mount(%{"theater_slug" => _theater_slug}, _session, socket) do
    # TODO we're going to need to get the exhibition by the theater_slug
    # exhibition  =
    #   Cinema.get_exhibition_by_theater!(slug: theater_slug)

    {:ok, socket}
  end
end
