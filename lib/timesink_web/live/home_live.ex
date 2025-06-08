defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics}
  import TimesinkWeb.Components.Hero

  def mount(_params, _session, socket) do
    showcase = Cinema.get_active_showcase_with_exhibitions()

    exhibitions =
      (showcase.exhibitions || [])
      |> Cinema.preload_exhibitions()
      |> Enum.sort_by(& &1.theater.name, :asc)

    playback_states = Timesink.Cinema.compute_initial_playback_states(exhibitions, showcase)

    socket =
      assign(socket,
        showcase: showcase,
        exhibitions: exhibitions,
        playback_states: playback_states,
        presence: %{}
      )

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
        exhibitions={@exhibitions}
        presence={@presence}
        playback_states={@playback_states || %{}}
      />
    </div>
    """
  end

  def handle_info(:connected, socket) do
    # Don't subscribe to scheduler topics from homepage (performance)
    # Only track presence for each theater
    presence =
      socket.assigns.showcase.exhibitions
      |> Enum.map(fn ex ->
        presence_topic = PubSubTopics.presence_topic(ex.theater_id)
        Phoenix.PubSub.subscribe(Timesink.PubSub, presence_topic)
        {presence_topic, Presence.list(presence_topic)}
      end)
      |> Enum.into(%{})

    {:noreply, assign(socket, :presence, presence)}
  end

  def handle_info(
        %{
          event: "phase_change",
          playback_state:
            %{
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
