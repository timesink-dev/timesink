defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view
  alias Timesink.Repo

  import Ecto.Query
  alias Timesink.Cinema
  alias Timesink.Presence
  alias Timesink.Cinema.Film
  alias Timesink.Cinema.Creative

  def mount(_params, _session, socket) do
    showcase =
      Cinema.Showcase
      |> where([s], s.status == :active)
      |> preload([:exhibitions])
      |> Repo.one()

    exhibitions =
      (showcase.exhibitions || [])
      |> Repo.preload([
        :theater,
        film: [:genres, video: [:blob], poster: [:blob], trailer: [:blob], directors: [:creative]]
      ])
      |> Enum.sort_by(& &1.theater.name, :asc)

    default_exhibition = List.first(exhibitions)

    if connected?(socket) do
      for ex <- exhibitions do
        topic = "theater:#{ex.theater_id}"
        Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
        Presence.track(self(), topic, socket.id, %{})
      end
    end

    {:ok,
     assign(socket,
       showcase: showcase,
       exhibitions: exhibitions,
       selected_theater_id: default_exhibition.theater.id,
       presence: %{}
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <!-- Hero -->
      <div id="hero" class="h-screen w-full bg-backroom-black text-white flex items-center justify-center">
        <h1 class="text-5xl font-bold">Welcome to TimeSink</h1>
      </div>

      <div class="bg-backroom-black py-16 px-6 flex flex-col lg:flex-row gap-10 max-w-7xl mx-auto">
        <!-- Vertical Nav -->
        <div class="flex flex-col space-y-12 w-full lg:w-1/4">
          <%= for exhibition <- @exhibitions do %>
            <div
              phx-click="select_theater"
              phx-value-id={exhibition.theater.id}
              class={[
                "bg-dark-theater-primary rounded-lg p-4 shadow-md cursor-pointer transition",
                "hover:bg-dark-theater-light",
                @selected_theater_id == exhibition.theater.id && "ring-1 ring-neon-blue-lightest"
              ]}
            >
              <div class="flex justify-between items-start mb-2">
                <h3 class="text-white font-semibold text-lg">
                  {exhibition.theater.name}
                </h3>
                <div class="text-xs text-white/60">
                  <.icon name="hero-user-group" class="h-5 w-5" />

                  {live_viewer_count("theater:#{exhibition.theater_id}", @presence)}
                </div>
              </div>
              <div class="mt-6 text-neon-red-light text-sm font-medium">
                {exhibition.film.title}
              </div>
            </div>
          <% end %>
        </div>

    <!-- Main Theater Viewer Section -->
        <div class="flex-1">
          <%= for exhibition <- @exhibitions,
              exhibition.theater.id == @selected_theater_id do %>
            <% film = exhibition.film %>

    <!-- Title and Description -->
            <div class="mb-6">
              <h3 class="text-3xl font-bold mb-1 text-left text-white drop-shadow-md">
                {exhibition.theater.name}
              </h3>
              <p class="text-sm text-white/60 text-left">
                {exhibition.theater.description || "No description available."}
              </p>
                      <div class="wrapper w-64 px-2 py-1 mb-6 overflow-hidden">
          <div class="marquee text-neon-red-light text-sm">
            <%= for part <- repeated_film_title_parts(exhibition.film.title) do %>
              <p>Now playing</p>
              <p>{part}</p>
            <% end %>
          </div>
        </div>
            </div>

    <!-- Video -->
            <div class="relative w-full aspect-video rounded-xl overflow-hidden shadow-2xl group transition-transform duration-300 hover:scale-[1.02] cursor-pointer">
            <%= if playback_id = Film.get_mux_playback_id(film.trailer) do %>

              <mux-player
                id={"mux-player-#{film.id}"}
                playback-id={Film.get_mux_playback_id(film.trailer)}
                muted
                loop
                playsinline
                preload="metadata"
                style="--controls: none;"
                class="w-full h-full object-cover group"
                phx-hook="HoverPlay"
              />
            <% else %>
              <img
                src={Film.poster_url(film.poster)}
                alt={film.title}
                class="w-full h-full object-cover"
              />
            <% end %>
            </div>

    <!-- Film Info -->
            <div class="space-y-3 text-white">
              <h4 class="text-2xl font-semibold">{film.title}</h4>

              <p class="text-white/70 text-sm">
                {film.year} • {film.duration} min
                <%= if film.genres != [] do %>
                  •
                  <%= for genre <- film.genres do %>
                    <span class="inline-block bg-gray-800 rounded-full px-2 py-1 text-xs ml-2">
                      {genre.name}
                    </span>
                  <% end %>
                <% end %>
              </p>

              <p class="text-white/80 text-base leading-relaxed">{film.synopsis}</p>

              <%= if Enum.any?(film.directors) do %>
                <p class="text-sm text-white/60 italic">
                  Directed by {join_names(film.directors)}
                </p>
              <% end %>

              <div class="flex items-center justify-between mt-6">
                <p class="text-white/50 text-sm">
                  {live_viewer_count("theater:#{exhibition.theater_id}", @presence)} watching now
                </p>

                <.link navigate={~p"/now-playing/#{exhibition.theater.slug}"}>
                  <.button>
                    Enter Theater →
                  </.button>
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_theater", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_theater_id: id)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = Presence.list(topic)
    updated_presence = Map.put(socket.assigns.presence, topic, presence)
    {:noreply, assign(socket, presence: updated_presence)}
  end

  defp live_viewer_count(theater_id, presence) do
    topic = "theater:#{theater_id}"
    Map.get(presence, topic, %{}) |> map_size()
  end

  defp join_names([]), do: ""

  defp join_names(creatives) do
    creatives
    |> Enum.map(fn %{creative: c} -> Creative.full_name(c) end)
    |> Enum.join(", ")
  end

    defp repeated_film_title_parts(title, repeat_count \\ 4) do
    1..repeat_count
    |> Enum.map(fn _ -> title end)
  end

end
