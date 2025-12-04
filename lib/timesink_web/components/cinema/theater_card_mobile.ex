defmodule TimesinkWeb.Components.TheaterCardMobile do
  use Phoenix.Component

  alias Timesink.Cinema.{Exhibition, Film}
  import TimesinkWeb.CoreComponents

  attr :exhibition, Exhibition, required: true
  attr :live_viewer_count, :integer, required: true
  attr :playback_state, :map, required: true
  attr :timezone, :string, required: true

  def theater_card_mobile(assigns) do
    ~H"""
    <div class="shrink-0 w-full">
      <% film = @exhibition.film %>
      <div class="mb-6 h-20">
        <h3 class="text-xl font-bold mb-1 text-left text-white drop-shadow-md font-gangster">
          {@exhibition.theater.name}
        </h3>
        <p class="text-sm text-white/60 text-left">
          {@exhibition.theater.description}
        </p>
        <div class="wrapper w-72 px-2 py-2 mb-2 overflow-hidden text-center">
          <div class="marquee text-neon-red-lightest text-sm uppercase">
            <%= case playback_phase(@playback_state) do %>
              <% :playing -> %>
                <%= for part <- repeated_film_title_parts(@exhibition.film.title) do %>
                  <p>Now Playing</p>
                  <p>{part}</p>
                <% end %>
              <% :intermission -> %>
                <%= for part <- repeated_film_title_parts(@exhibition.film.title) do %>
                  <p>Intermission{format_next_showing(@playback_state, @timezone)}</p>
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
      <div class="relative rounded-xl w-full aspect-video min-h-[240px] overflow-hidden group">
        <mux-player
          id={"mux-player-#{film.id}-mobile#{Enum.random(?a..?z)}"}
          playback-id={Film.get_mux_playback_id(film.trailer)}
          muted
          loop
          playsinline
          preload="metadata"
          style="--controls: none;"
          class="absolute inset-0 w-full h-full object-cover pointer-events-none brightness-75 transition-transform duration-500 group-hover:brightness-85"
          phx-hook="HoverPlay"
        />
      </div>

      <div class="text-mystery-white px-4 pt-3 pb-8 space-y-3">
        <h3 class="text-xl font-bold">{film.title}</h3>

        <div class="text-xs text-white/70 space-x-2">
          <span>{film.year} •</span>
          <span>{film.duration} min</span>
        </div>

        <%= if film.genres && film.genres != [] do %>
          <ul class="flex flex-wrap gap-2">
            <%= for genre <- film.genres do %>
              <li class="bg-dark-theater-primary rounded-full px-2 py-1 text-xs">
                {genre.name}
              </li>
            <% end %>
          </ul>
        <% end %>

        <p class="text-sm text-gray-300 line-clamp-4 leading-snug">
          {film.synopsis}
        </p>

        <%= if Enum.any?(film.directors) do %>
          <div class="text-xs text-white/60">
            Directed by {join_names(film.directors)}
          </div>
        <% end %>

        <%= if Enum.any?(film.cast) do %>
          <div class="text-xs text-white/60">
            Cast: {join_names(film.cast)}
          </div>
        <% end %>

        <div class="flex items-center justify-between pt-2">
          <p class="text-white/40 text-md">
            <.icon name="hero-user-group" class="h-5 w-5 inline-block" /> {@live_viewer_count}
          </p>
          <.link navigate={"/now-playing/#{@exhibition.theater.slug}"}>
            <.button class="cursor-pointer">
              Enter theater →
            </.button>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp join_names([]), do: ""

  defp join_names(creatives) do
    creatives
    |> Enum.map(fn %{creative: c} -> "#{c.first_name} #{c.last_name}" end)
    |> Enum.join(", ")
  end

  defp repeated_film_title_parts(title, repeat_count \\ 4) do
    1..repeat_count
    |> Enum.map(fn _ -> title end)
  end

  defp playback_phase(%{phase: phase}) when not is_nil(phase), do: phase
  defp playback_phase(_), do: :unknown

  defp format_next_showing(%{countdown: countdown}, timezone) when is_integer(countdown) do
    next_showing_time =
      DateTime.utc_now()
      |> DateTime.add(countdown, :second)
      |> DateTime.shift_zone!(timezone)

    time_string = Calendar.strftime(next_showing_time, "%I:%M %p")
    " -- Next Showing At #{time_string}"
  end

  defp format_next_showing(_, _), do: ""
end
