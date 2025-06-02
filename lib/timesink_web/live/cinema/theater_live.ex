defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Theater
  alias Timesink.Cinema.Exhibition
  alias Timesink.Cinema.Showcase
  alias Timesink.Cinema.Film
  alias Timesink.Cinema.Creative
  alias Timesink.Repo

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      if connected?(socket) do
        topic = "theater:#{theater.id}"

        Phoenix.PubSub.subscribe(Timesink.PubSub, topic)

        TimesinkWeb.Presence.track(
          self(),
          topic,
          # can be user.id or username
          "#{socket.assigns.current_user.id}",
          %{
            username: socket.assigns.current_user.username,
            joined_at: System.system_time(:second)
          }
        )
      end

      {:ok,
       socket
       |> assign(:theater, theater)
       |> assign(
         :film,
         film
         |> Repo.preload([
           {:video, [:blob]},
           {:poster, [:blob]},
           :genres,
           directors: [:creative],
           cast: [:creative],
           writers: [:creative],
           producers: [:creative],
           crew: [:creative]
         ])
       )
       |> assign(:exhibition, exhibition)
       |> assign(:user, socket.assigns.current_user)
       |> assign(:presence, %{})}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div
      id="theater"
      class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100 mt-16 flex justify-between gap-x-12"
    >
      <div class="flex-1">
        <div class="border-b border-gray-700 pb-4">
          <h1 class="text-xl font-bold">{@theater.name}</h1>
          <p class="text-gray-400 mt-2 text-sm">{@theater.description}</p>
        </div>

        <div>
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
        </div>

        <div
          id="film-info"
          class="w-full max-w-3xl mt-10 mx-4 border-t border-gray-700 pt-6 space-y-4"
        >
          <!-- Title + Year + Duration -->
          <div class="text-2xl font-semibold tracking-wide text-mystery-white">
            {@film.title}
            <span class="text-gray-400 text-base ml-2">({@film.year})</span>
          </div>

          <div class="text-sm text-mystery-white uppercase tracking-wider flex flex-wrap gap-x-4 gap-y-2">
            <%= for genre <- @film.genres do %>
              <span>{genre.name}</span>
            <% end %>
            <span>•</span>
            <span>{@film.duration} min</span>
            <span>•</span>
            <span>{String.upcase(to_string(@film.format))}</span>
            <span>•</span>
            <span>{@film.aspect_ratio} aspect</span>
            <%= if @film.color do %>
              <span>•</span>
              <span class="capitalize">{String.replace(to_string(@film.color), "_", " ")}</span>
            <% end %>
          </div>

          <div class="text-base text-gray-300 leading-relaxed font-light max-w-prose">
            {@film.synopsis}
          </div>

          <div class="text-sm text-gray-400 font-light space-y-2 pt-4 border-t border-gray-800 mt-6">
            <%= if Enum.any?(@film.directors) do %>
              <div>
                <span class="text-gray-500 uppercase tracking-wider">Director:</span>
                <span class="text-gray-300">
                  {join_names(@film.directors)}
                </span>
              </div>
            <% end %>

            <%= if Enum.any?(@film.writers) do %>
              <div>
                <span class="text-gray-500 uppercase tracking-wider">Writer:</span>
                <span class="text-gray-300">
                  {join_names(@film.producers)}
                </span>
              </div>
            <% end %>

            <%= if Enum.any?(@film.producers) do %>
              <div>
                <span class="text-gray-500 uppercase tracking-wider">Producer:</span>
                <span class="text-gray-300">
                  {join_names(@film.producers)}
                </span>
              </div>
            <% end %>

            <%= if Enum.any?(@film.cast) do %>
              <div>
                <span class="text-gray-500 uppercase tracking-wider">Cast:</span>
                <ul class="text-gray-300 list-disc list-inside">
                  {join_names_with_roles(@film.cast)}
                </ul>
              </div>
            <% end %>

            <%= if Enum.any?(@film.crew) do %>
              <div>
                <span class="text-gray-500 uppercase tracking-wider">Crew:</span>
                <ul class="text-gray-300 list-disc list-inside">
                  {join_names_with_roles(@film.crew)}
                </ul>
              </div>
            <% end %>
          </div>

          <div class="pt-6">
            <.button color="tertiary" class="hover:cursor-not-allowed" disabled>
              Tip the Filmmaker
            </.button>
          </div>
        </div>
        <div class="text-sm text-gray-500 italic mt-32">
          More interactive features (chat, playback, etc.) coming soon.
        </div>
      </div>
      <div class="text-sm text-backroom-black pt-6">
        <div class="flex justify-between items-center">
          <h4 class="text-xs text-center tracking-wider mb-2 bg-[#AEF855] text-backroom-black py-1 px-2 rounded">
            Live audience <span>({live_viewer_count(@theater.id, @presence)})</span>
          </h4>
        </div>
        <ul class="list-none text-mystery-white space-y-1">
          <%= @presence
    |> Enum.map(fn {_id, %{metas: metas}} -> List.first(metas)end)
    |> Enum.map(fn meta -> %>
            <li>{meta.username}</li>
          <% end) %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = TimesinkWeb.Presence.list(topic)
    {:noreply, assign(socket, presence: presence)}
  end

  defp repeated_film_title_parts(title, repeat_count \\ 4) do
    1..repeat_count
    |> Enum.map(fn _ -> title end)
  end

  defp join_names([]), do: ""

  defp join_names(creatives) do
    creatives
    |> Enum.map(fn %{creative: c} -> Creative.full_name(c) end)
    |> Enum.join(", ")
  end

  defp join_names_with_roles([]), do: ""

  defp join_names_with_roles(creatives) do
    creatives
    |> Enum.map(fn %{creative: c, subrole: r} ->
      case r do
        nil -> Creative.full_name(c)
        "" -> Creative.full_name(c)
        _ -> "#{Creative.full_name(c)} (#{r})"
      end
    end)
    |> Enum.join(", ")
  end

  defp live_viewer_count(_theater_id, presence), do: map_size(presence)
end
