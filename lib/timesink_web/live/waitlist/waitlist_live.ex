defmodule TimesinkWeb.WaitlistLive do
  use TimesinkWeb, :live_view
  alias Timesink.Waitlist

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(10_000, self(), :update_waitlist_status)
    end

    spots_remaining = Waitlist.get_wave_spots_remaining()

    hero_url = TimesinkWeb.Endpoint.url() <> "/images/timesink_hero.webp"

    {:ok,
     assign(socket,
       sent?: false,
       spots_remaining: spots_remaining,
       page_title: "Join TimeSink",
       og_title: "Join TimeSink",
       og_description:
         "Request an invitation to TimeSink — a curated, communal cinema experience for real film lovers.",
       og_image: hero_url,
       og_url: TimesinkWeb.Endpoint.url() <> "/join"
     ), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen bg-backroom-black flex items-center justify-center overflow-hidden">
      <.live_component
        module={TimesinkWeb.Components.WaitlistForm}
        id="waitlist_form"
        sent?={@sent?}
        spots_remaining={@spots_remaining}
      />
    </div>
    """
  end

  def handle_info(:applicant_joined, socket) do
    socket = assign(socket, sent?: true)
    {:noreply, socket}
  end

  def handle_info(:update_waitlist_status, socket) do
    spots = Waitlist.get_wave_spots_remaining()
    {:noreply, assign(socket, spots_remaining: spots)}
  end
end
