defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent}
  import TimesinkWeb.Components.Hero

  def mount(_params, _session, socket) do
    showcase =
      Cinema.get_active_showcase_with_exhibitions()

    socket = socket |> assign(:showcase, showcase) |> assign(:presence, %{})

    if connected?(socket), do: send(self(), :connected)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <div
        id="hero"
        class="h-screen w-full bg-backroom-black text-white flex items-center justify-center"
      >
        <.hero />
      </div>
      <div id="cinema-barrier" class="h-16" phx-hook="ScrollObserver" />
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

  def handle_info(
        %{
          event: "tick",
          playback_state:
            %{
              phase: _phase,
              offset: _offset,
              countdown: _countdown,
              theater_id: theater_id
            } = playback_state
        },
        socket
      ) do
    updated_states =
      Map.update(socket.assigns[:playback_states] || %{}, theater_id, playback_state, fn _ ->
        playback_state
      end)

    {:noreply, assign(socket, :playback_states, updated_states)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    {:noreply, update(socket, :presence, &Map.put(&1, topic, updated))}
  end
end
