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
    <div id="theater" class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100 mt-16">
      <%!-- <div class="border-b border-gray-700 pb-4">
        <h1 class="text-3xl font-bold text-white">{@theater.name}</h1>
        <p class="text-gray-400 mt-2">{@theater.description}</p>
      </div> --%>

      <div>
        <h1>{@theater.name}</h1>
        <div class="my-2 text-neon-blue-lightest text-xs mb-4">
          Now playing • {@film.title}
        </div>
        <div class="wrapper w-64 px-2 py-1 mb-6 overflow-hidden">
          <div class="marquee text-neon-red-light text-xs">
            <%= for part <- repeated_film_title_parts(@film.title) do %>
              <p>Now playing</p>
              <p>{part}</p>
            <% end %>
          </div>
        </div>
        <%!-- <div class="bg-dark-theater-primary rounded-lg py-6 px-4"> --%>
        <%!-- <h3 class="text-xl font-bold text-white my-4">
            {@film.title}
            <span class="text-gray-400">({@film.year})</span>
          </h3> --%>
        <%= if playback_id = Film.get_mux_playback_id(@film.video) do %>
          <mux-player
            playback-id={playback_id}
            metadata-video-title={@film.title}
            metadata-video-id={@film.id}
            metadata-viewer_user_id={@user.id}
            poster={Film.poster_url(@film.poster)}
            style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 8px; overflow: hidden; border-color: #1f2937; border-width: 1px;"
            stream-type="live"
            autoplay
            loop
          />
        <% end %>

        <%!-- <p class="text-gray-300 mt-1">by <%= @film.author %></p> --%>
        <%!-- <%= if @film.poster_url do %>
            <img src={@film.poster_url} alt="Film Poster" class="mt-4 rounded-lg w-64 shadow-lg" />
          <% end %> --%>
        <%!-- </div> --%>
      </div>

      <div class="text-sm text-gray-500 italic">
        More interactive features (chat, playback, etc.) coming soon.
      </div>
      <%!-- <div id="film-info" class="flex justify-between w-full">
        <div class="flex flex-col gap-y-4 text-gray-400">
          {@film.title}
          <div>
            <span>
              {@film.year}
            </span>
            <span class="mx-2">•</span>
            <span>
              {@film.duration} min
            </span>
          </div>
          <div class="text-gray-400">{@film.synopsis}</div>
        </div>
        <%!-- <div>
          <span class="text-gray-400">Format:</span>
          <span class="text-gray-300">
            {@film.format}
          </span>
          <span class="mx-2">•</span>
          <span class="text-gray-400">Aspect Ratio:</span>
          <span class="text-gray-300">
            {@film.aspect_ratio}
          </span>
        </div> --%>
      <%!-- <div>
          <.button color="tertiary">Tip the project</.button>
        </div>
      </div> --%>
    </div>
    """
  end

  defp repeated_film_title_parts(title, repeat_count \\ 4) do
    1..repeat_count
    |> Enum.map(fn _ -> title end)
  end
end
