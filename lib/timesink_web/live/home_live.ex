defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view
  alias Timesink.Repo

  import Ecto.Query
  alias Timesink.Cinema
  alias Timesink.Presence
  alias Timesink.Cinema.Film
  alias Timesink.Cinema.Creative

  # no @topic — we'll use dynamic topics like "theater:#{id}"

  def mount(_params, _session, socket) do
    showcase =
      Timesink.Cinema.Showcase
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

    # Track presence per exhibition/theater
    if connected?(socket) do
      for ex <- exhibitions do
        topic = "theater:#{ex.theater_id}"
        Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
        Timesink.Presence.track(self(), topic, socket.id, %{})
      end
    end

    {:ok,
     assign(socket,
       showcase: showcase,
       exhibitions: exhibitions,
       presence: %{}
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <div id="hero" class="h-screen w-full bg-black text-white flex items-center justify-center">
        <h1 class="text-5xl font-bold">Welcome to TimeSink</h1>
      </div>
      
    <!-- Showcase title -->
      <div class="bg-neutral-900 py-12">
        <h2 class="text-3xl font-semibold text-white px-6 mb-6">Now Showing</h2>
      </div>
      
    <!-- Vertical scrollable exhibition sections -->
      <%= for exhibition <- @exhibitions do %>
        <% film = exhibition.film %>
        <% genres = Enum.map(film.genres, & &1.name) |> Enum.join(", ") %>

        <section class="bg-backroom-black py-16 px-4">
          <!-- Theater label -->
          <div class="max-w-4xl mx-auto mb-4">
            <h2 class="text-3xl font-bold text-center text-neon-blue-lightest  drop-shadow-md">
              {exhibition.theater.name}
            </h2>
          </div>
          
    <!-- Card container -->
          <div class="max-w-4xl mx-auto">
            <div class="relative w-full aspect-video rounded-xl overflow-hidden shadow-2xl group transition-transform duration-300 hover:scale-[1.02] cursor-pointer">
              <!-- Mux player background -->
              <mux-player
                id={"mux-player-#{film.id}"}
                playback-id={Film.get_mux_playback_id(film.trailer)}
                muted
                loop
                playsinline
                preload="metadata"
                style="--controls: none;"
                class="absolute inset-0 w-full h-full object-cover pointer-events-none brightness-75 transition-transform duration-500 group-hover:brightness-90 group-hover:scale-105"
                phx-hook="HoverPlay"
              />
              
    <!-- Overlay -->
              <div class="absolute inset-0 bg-gradient-to-t from-black/80 to-black/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex flex-col justify-end p-6 space-y-2 z-10">
                <h3 class="text-2xl font-bold">{film.title}</h3>
                <div class="text-sm text-white/70">
                  <span>{film.year} &nbsp; •</span>
                  <span class="inline-block px-2 py-1 mr-2">
                    {film.duration} min
                  </span>
                  <%= if film.genres && film.genres != [] do %>
                    <ul class="inline-block">
                      <%= for genre <- film.genres do %>
                        <li class="inline-block bg-dark-theater-primary rounded-full px-2 py-1 mr-2 text-xs">
                          {genre.name}
                        </li>
                      <% end %>
                    </ul>
                  <% end %>
                </div>
                <p class="text-xs text-white/60 line-clamp-3">{film.synopsis}</p>

                <%= if Enum.any?(film.directors) do %>
                  <div class="text-xs text-white/50">
                    Directed by {join_names(film.directors)}
                  </div>
                <% end %>

                <div class="mt-2 flex items-center justify-between">
                  <p class="text-white/40 text-md">
                    <.icon name="hero-user-group" class="h-6 w-6" /> {live_viewer_count(
                      "theater:#{exhibition.theater_id}",
                      @presence
                    )}
                  </p>
                  <.link navigate={~p"/now-playing/#{exhibition.theater.slug}"}>
                    <.button>
                      Enter Theater →
                    </.button>
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </section>
      <% end %>
    </div>
    """
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = Presence.list(topic)

    updated_presence =
      Map.put(socket.assigns.presence, topic, presence)

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
end
