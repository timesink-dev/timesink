defmodule TimesinkWeb.Cinema.NowPlayingLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics}

  def mount(_params, _session, socket) do
    with showcase when not is_nil(showcase) <- Cinema.get_active_showcase_with_exhibitions() do
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
          presence: %{},
          upcoming_showcase: nil,
          no_showcase: false
        )

      if connected?(socket), do: send(self(), :connected)
      {:ok, socket}
    else
      nil ->
        case Cinema.get_upcoming_showcase() do
          %{} = upcoming ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: upcoming,
               no_showcase: false
             )}

          nil ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: nil,
               no_showcase: true
             )}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div id="now-playing">
      <%= cond do %>
        <% @showcase -> %>
          <.live_component
            id="theater-showcase"
            module={TheaterShowcaseComponent}
            showcase={@showcase}
            exhibitions={@exhibitions}
            presence={@presence}
            playback_states={@playback_states}
          />
        <% @upcoming_showcase -> %>
          <div class="text-center text-white my-32 px-6 max-w-xl mx-auto h-[100vh] flex flex-col items-center justify-center">
            <.icon name="hero-clock" class="h-16 w-16 mb-6 text-neon-blue-lightest" />
            <h1 class="text-4xl font-bold mb-4">Upcoming Showcase</h1>
            <h2 class="text-2xl font-semibold text-neon-blue-lightest mb-2">
              {@upcoming_showcase.title}
            </h2>
            <p class="text-gray-400 mb-4">
              {@upcoming_showcase.description}
            </p>
            <p class="text-gray-500 text-sm">
              Starts
              <span class="font-medium">
                {Calendar.strftime(@upcoming_showcase.start_at, "%A, %B %d at %H:%M")}
              </span>
            </p>
          </div>
        <% @no_showcase -> %>
          <div class="text-center text-white my-32 px-6 max-w-xl mx-auto h-[100vh] flex flex-col items-center justify-center">
            <.icon name="hero-film" class="h-16 w-16 mb-6 text-neon-blue-lightest" />
            <h1 class="text-4xl font-bold mb-4">No Showcases Available</h1>
            <p class="text-gray-400 mb-8">
              It seems like there are no active or upcoming showcases at the moment.
              Check back later for new screenings!
            </p>
            <p class="text-gray-500 text-sm">
              In the meantime, feel free to explore our
              <a href="/blog" class="text-neon-blue-lightest hover:underline">blog</a>
              for insights and updates.
            </p>
          </div>
      <% end %>
    </div>
    """
  end

  def handle_info(:connected, socket) do
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
