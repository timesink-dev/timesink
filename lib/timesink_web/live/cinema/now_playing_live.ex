defmodule TimesinkWeb.Cinema.NowPlayingLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent}

  def mount(_params, _session, socket) do
    showcase =
      Cinema.get_active_showcase_with_exhibitions()

    socket = socket |> assign(:showcase, showcase) |> assign(:presence, %{})

    if connected?(socket), do: send(self(), :connected)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="now-playing">
      <.live_component
        id="theater-showcase"
        module={TheaterShowcaseComponent}
        showcase={@showcase}
        presence={@presence}
      />
    </div>
    """
  end

  def handle_info(:connected, socket) do
    Enum.each(socket.assigns.showcase.exhibitions, fn ex ->
      topic = "theater:#{ex.theater_id}"
      Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
    end)

    presence =
      socket.assigns.showcase.exhibitions
      |> Enum.map(&"theater:#{&1.theater_id}")
      |> Enum.map(&{&1, Presence.list(&1)})
      |> Enum.into(%{})

    {:noreply, assign(socket, :presence, presence)}
  end

  def handle_info(%{event: "tick", offset: offset, interval: interval}, socket) do
    # This assumes you're tracking a selected theater's offset
    {:noreply, assign(socket, current_offset: offset, interval: interval)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    {:noreply, update(socket, :presence, &Map.put(&1, topic, updated))}
  end
end
