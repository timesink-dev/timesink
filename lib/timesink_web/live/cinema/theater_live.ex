defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film}
  alias Timesink.Repo
  require Logger

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      exhibition = Repo.preload(exhibition, [:showcase, :theater])

      film =
        Repo.preload(film, [
          {:video, [:blob]},
          {:poster, [:blob]},
          :genres,
          directors: [:creative],
          cast: [:creative],
          writers: [:creative],
          producers: [:creative],
          crew: [:creative]
        ])

      if connected?(socket) do
        topic = "theater:#{theater.id}"
        Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
        Phoenix.PubSub.subscribe(Timesink.PubSub, topic)

        TimesinkWeb.Presence.track(self(), topic, "#{socket.assigns.current_user.id}", %{
          username: socket.assigns.current_user.username,
          joined_at: System.system_time(:second)
        })
      end

      {:ok,
       socket
       |> assign(:theater, theater)
       |> assign(:exhibition, exhibition)
       |> assign(:film, film)
       |> assign(:user, socket.assigns.current_user)
       |> assign(:presence, %{})
       |> assign(:started, false)
       |> assign(:offset, nil)
       |> assign(:countdown, nil)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  def handle_info(%{event: "tick", offset: offset, interval: interval}, socket) do
    push_event(socket, "sync_offset", %{offset: offset})

    Logger.debug("Pushing sync_offset event with offset=#{offset}")

    film_duration = 30

    cond do
      offset < 0 ->
        {:noreply, assign(socket, started: false, countdown: abs(offset), offset: nil)}

      offset >= 0 and offset < film_duration ->
        {:noreply, assign(socket, started: true, offset: offset, countdown: nil)}

      offset >= film_duration ->
        {:noreply, assign(socket, started: false, countdown: interval - offset, offset: nil)}
    end
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = TimesinkWeb.Presence.list(topic)
    {:noreply, assign(socket, presence: presence)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="theater"
      class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100 mt-16 flex justify-between gap-x-12"
    >
      <div class="flex-1">
        <div class="border-b border-gray-700 pb-4 mb-10">
          <h1 class="text-xl font-bold">{@theater.name}</h1>
          <p class="text-gray-400 mt-2 text-sm">{@theater.description}</p>
        </div>

        <div>
          <% playback_id = Film.get_mux_playback_id(@film.video) %>
          <%= if @started and playback_id do %>
            <div id="simulated-live-player" data-offset={@offset} phx-hook="SimulatedLivePlayback">
              <mux-player
                id={@film.title}
                playback-id={playback_id}
                metadata-video-title={@film.title}
                metadata-video-id={@film.id}
                metadata-viewer_user_id={@user.id}
                poster={Film.poster_url(@film.poster)}
                style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 8px; overflow: hidden; border-color: #1f2937; border-width: 1px;"
                stream-type="live"
                autoplay
                loop
                start-time={@offset}
              />
            </div>
          <% else %>
            <div class="text-center text-gray-400 text-xl py-8">
              <%= if is_nil(@countdown) do %>
                <div class="flex items-center justify-center gap-2 text-gray-400">
                  <div class="h-4 w-4 border-2 border-t-transparent border-gray-400 rounded-full animate-spin">
                  </div>
                  <span>Intermission in progress...</span>
                </div>
              <% else %>
                Next screening starts in {@countdown} seconds
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
