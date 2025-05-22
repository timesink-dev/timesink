defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view
  alias Timesink.Repo

  import Ecto.Query
  import TimesinkWeb.TheaterCard

  alias Timesink.Cinema
  alias TimesinkWeb.Presence
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
        film: [
          :genres,
          video: [:blob],
          poster: [:blob],
          trailer: [:blob],
          directors: [:creative],
          cast: [:creative],
          writers: [:creative],
          producers: [:creative],
          crew: [:creative]
        ]
      ])
      |> Enum.sort_by(& &1.theater.name, :asc)

    # default_exhibition = List.first(exhibitions)

    default_index = 0
    default_exhibition = Enum.at(exhibitions, default_index)

    socket =
      socket
      |> assign(:showcase, showcase)
      |> assign(:exhibitions, exhibitions)
      |> assign(:selected_theater_id, default_exhibition.theater.id)
      |> assign(:selected_index, default_index)
      |> assign(:presence, %{})

    if connected?(socket), do: send(self(), :connected)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <!-- Hero -->
      <div
        id="hero"
        class="h-screen w-full bg-backroom-black text-white flex items-center justify-center"
      >
        <h1 class="text-5xl font-bold">Welcome to TimeSink</h1>
      </div>
      
    <!-- Responsive layout wrapper -->
      <div class="bg-backroom-black py-16 px-6 max-w-7xl mx-auto">
        
    <!-- DESKTOP LAYOUT: vertical nav + film detail -->
        <div class="hidden lg:flex flex-row gap-24">
          <!-- Vertical Nav -->
          <div class="flex flex-col space-y-12 w-1/5">
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
                <div class="mt-6 text-neon-red-lightest text-sm font-medium">
                  {exhibition.film.title}
                </div>
              </div>
            <% end %>
          </div>
          
    <!-- Film Detail -->
          <div class="flex-1">
            <%= for exhibition <- @exhibitions do %>
              <div class={
                if exhibition.theater.id == @selected_theater_id, do: "block", else: "hidden"
              }>
                <% film = exhibition.film %>

                <div class="mb-6">
                  <h3 class="text-3xl font-bold mb-1 text-left text-white drop-shadow-md">
                    {exhibition.theater.name}
                  </h3>
                  <p class="text-sm text-white/60 text-left">
                    {exhibition.theater.description}
                  </p>
                  <div class="wrapper w-64 px-2 py-1 mb-6 overflow-hidden">
                    <div class="marquee text-neon-red-light text-sm">
                      <%= for part <- repeated_film_title_parts(film.title) do %>
                        <p>Now playing</p>
                        <p>{part}</p>
                      <% end %>
                    </div>
                  </div>
                </div>

                <div class="max-w-4xl">
                  <div class="relative w-full aspect-video rounded-xl overflow-hidden shadow-2xl group transition-transform duration-300 hover:scale-[1.02] cursor-pointer">
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
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- MOBILE/TABLET LAYOUT: Carousel -->
        <div class="block lg:hidden px-4 space-y-6 max-w-screen-lg mx-auto">
          <!-- Main Embla Carousel -->
          <div id="embla-main" phx-hook="EmblaMain" class="overflow-hidden">
            <div class="flex gap-4 px-4">
              <%= for exhibition <- @exhibitions do %>
                <div class="shrink-0 w-full">
                  <div class="mb-6">
                    <h3 class="text-3xl font-bold mb-1 text-left text-white drop-shadow-md">
                      {exhibition.theater.name}
                    </h3>
                    <p class="text-sm text-white/60 text-left">
                      {exhibition.theater.description}
                    </p>
                  </div>
                  <.theater_card
                    exhibition={exhibition}
                    live_viewer_count={
                      live_viewer_count(
                        "theater:#{exhibition.theater_id}",
                        @presence
                      )
                    }
                  />
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Thumbnail Carousel -->
          <div id="embla-thumbs" phx-hook="EmblaThumbs" class="overflow-hidden w-full p-2">
            <div class="flex gap-2">
              <%= for {exhibition, index} <- Enum.with_index(@exhibitions) do %>
                <img
                  src={Timesink.Cinema.Film.poster_url(exhibition.film.poster)}
                  alt={exhibition.film.title}
                  data-thumb-index={index}
                  class={[
                    "object-cover rounded-md w-28 h-28 transition-all duration-300 cursor-pointer",
                    index == @selected_index && "ring-2 ring-neon-blue-lightest"
                  ]}
                />
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_theater", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_theater_id: id)}
  end

  def handle_event("select_thumbnail", %{"index" => index}, socket) do
    exhibitions = socket.assigns.exhibitions
    selected = Enum.at(exhibitions, String.to_integer(index))

    {:noreply,
     assign(socket,
       selected_index: index,
       selected_theater_id: selected.theater.id
     )}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    new_presence = Map.put(socket.assigns.presence, topic, updated)
    {:noreply, assign(socket, :presence, new_presence)}
  end

  def handle_info(:connected, socket) do
    exhibitions = socket.assigns.exhibitions

    Enum.each(exhibitions, fn ex ->
      topic = "theater:#{ex.theater_id}"
      Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
    end)

    updated_presence =
      Enum.reduce(exhibitions, %{}, fn ex, acc ->
        topic = "theater:#{ex.theater_id}"
        Map.put(acc, topic, Presence.list(topic))
      end)

    {:noreply, assign(socket, :presence, updated_presence)}
  end

  defp live_viewer_count(theater_id, presence) do
    # determine the joining (before it was "theater:#{theater_id}"), but that was producing
    # a dpulicate "theater:theater:#{theater_id}" topic
    topic = "#{theater_id}"
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
