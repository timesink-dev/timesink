defmodule TimesinkWeb.Components.TheaterCard do
  use Phoenix.Component

  import TimesinkWeb.CoreComponents

  alias Timesink.Cinema.{Exhibition, Film, Creative}

  attr :exhibition, Exhibition, required: true
  attr :live_viewer_count, :integer, required: true
  attr :playback_state, :map, required: true

  def theater_card(assigns) do
    ~H"""
    <div>
      <% film = @exhibition.film %>
      <div class="mb-6 h-20">
        <h3 class="text-xl font-bold mb-1 text-left text-white drop-shadow-md font-brand">
          {@exhibition.theater.name}
        </h3>
        <p class="text-sm text-white/60 text-left">
          {@exhibition.theater.description}
        </p>
        <div class="wrapper w-64 px-2 py-1 mb-6 overflow-hidden">
          <div class="marquee text-neon-red-lightest text-sm uppercase">
            <%= case playback_phase(@playback_state) do %>
              <% :playing -> %>
                <%= for part <- repeated_film_title_parts(@exhibition.film.title) do %>
                  <p>Now Playing</p>
                  <p>{part}</p>
                <% end %>
              <% :intermission -> %>
                <%= for part <- repeated_film_title_parts(@exhibition.film.title) do %>
                  <p>Intermission</p>
                  <p>{part}</p>
                <% end %>
              <% :upcoming -> %>
                <%= for part <- repeated_film_title_parts(@exhibition.film.title) do %>
                  <p>Upcoming Showcase</p>
                  <p>{part}</p>
                <% end %>
              <% _ -> %>
                <p>Loading…</p>
            <% end %>
          </div>
        </div>
      </div>

      <div class="max-w-4xl">
        <div class="relative w-full aspect-video rounded-xl overflow-hidden shadow-2xl group transition-transform duration-300 hover:scale-[1.02]">
          <mux-player
            id={"mux-player-#{film.id}"}
            playback-id={Film.get_mux_playback_id(film.trailer)}
            muted
            loop
            playsinline
            preload="metadata"
            style="--controls: none;"
            class="absolute inset-0 w-full h-full object-cover pointer-events-none brightness-75 transition-transform duration-500 group-hover:brightness-85"
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
            <p class="text-xs text-white/60 line-clamp-3 w-80">{film.synopsis}</p>

            <%= if Enum.any?(film.directors) do %>
              <div class="text-xs text-white/50">
                Directed by {join_names(film.directors)}
              </div>
            <% end %>

            <div class="mt-2 flex items-center justify-between">
              <p class="text-white/40 text-md">
                <.icon name="hero-user-group" class="h-6 w-6" /> {@live_viewer_count}
              </p>
              <.link navigate={"/now-playing/#{@exhibition.theater.slug}"}>
                <.button class="cursor-pointer">
                  Enter theater →
                </.button>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
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

  defp playback_phase(%{phase: phase}) when not is_nil(phase), do: phase
  defp playback_phase(_), do: :unknown
end
