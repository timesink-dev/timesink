defmodule TimesinkWeb.TheaterCard do
  use Phoenix.Component

  alias Timesink.Cinema.{Film, Exhibition}
  # if you want to reuse .button, .icon, etc.
  import TimesinkWeb.CoreComponents

  attr :exhibition, :map, required: true

  def theater_card(assigns) do
    ~H"""
    <% film = @exhibition.film %>

    <div class="rounded-xl overflow-hidden shadow-xl bg-black text-white w-full">
      <div class="relative aspect-video">
        <img
          src={Film.poster_url(film.poster)}
          alt={"Poster of #{film.title}"}
          class="w-full h-full object-cover"
        />
        <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black via-black/70 to-transparent p-4 space-y-2">
          <h3 class="text-lg font-bold tracking-wide text-white">
            {film.title}
          </h3>
          <div class="text-xs uppercase text-gray-300 space-x-2">
            <span>{film.year}</span>
            <%= for genre <- film.genres do %>
              <span>{genre.name}</span>
            <% end %>
          </div>
          <p class="text-sm text-gray-200 line-clamp-3">
            {film.synopsis}
          </p>

          <div class="text-xs text-gray-400 mt-2">
            <%= if Enum.any?(film.directors) do %>
              <p><span class="font-semibold">Director:</span> {join_names(film.directors)}</p>
            <% end %>
            <%= if Enum.any?(film.cast) do %>
              <p><span class="font-semibold">Cast:</span> {join_names(film.cast)}</p>
            <% end %>
          </div>
        </div>
      </div>
      <div class="text-center text-sm mt-4 text-gray-400 italic">
        Now playing {film.title}
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
end
