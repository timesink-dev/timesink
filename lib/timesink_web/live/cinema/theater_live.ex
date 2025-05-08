defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Theater
  alias Timesink.Cinema.Exhibition
  alias Timesink.Cinema.Showcase
  alias Timesink.Cinema.Film
  alias Timesink.Repo

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      {:ok,
       socket
       |> assign(:theater, theater)
       |> assign(:film, film |> Repo.preload(video: [:blob], poster: [:blob]))
       |> assign(:exhibition, exhibition)
       |> assign(:user, socket.assigns.current_user)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/@mux/mux-player" defer>
    </script>
    <div id="theater" class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100">
      <div class="border-b border-gray-700 pb-4">
        <h1 class="text-3xl font-bold text-white">{@theater.name}</h1>
        <p class="text-gray-400 mt-2">{@theater.description}</p>
      </div>

      <div>
        <h2 class="text-2xl font-semibold text-gray-200 mb-2">Now Playing:</h2>
        <div class="bg-dark-theater-primary rounded-lg p-4 shadow-md border border-gray-700">
          <h3 class="text-xl font-bold text-white">
            {@film.title}
            <span class="text-gray-400">({@film.year})</span>
          </h3>
          <%= if playback_id = Film.get_mux_playback_id(@film.video) do %>
            <mux-player
              playback-id={playback_id}
              metadata-video-title={@film.title}
              metadata-video-id={@film.id}
              metadata-viewer_user_id={@user.id}
              poster={Film.poster_url(@film.poster)}
              style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 12px; overflow: hidden;"
              stream-type="live"
              autoplay
              loop
            />
          <% end %>

          <%!-- <p class="text-gray-300 mt-1">by <%= @film.author %></p> --%>
          <%!-- <%= if @film.poster_url do %>
            <img src={@film.poster_url} alt="Film Poster" class="mt-4 rounded-lg w-64 shadow-lg" />
          <% end %> --%>
        </div>
      </div>

      <div class="text-sm text-gray-500 italic">
        More interactive features (chat, playback, etc.) coming soon.
      </div>
    </div>
    """
  end
end
