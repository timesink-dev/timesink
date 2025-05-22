defmodule TimesinkWeb.Components.TheaterCardMobile do
  use Phoenix.Component

  alias Timesink.Cinema.Film
  import TimesinkWeb.CoreComponents

  attr :exhibition, :map, required: true
  attr :live_viewer_count, :integer, required: false

  def theater_card_mobile(assigns) do
    ~H"""
    <% film = @exhibition.film %>

    <div class="rounded-md overflow-hidden shadow-xl bg-black text-white w-full">
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

          <div class="mt-2 flex items-center justify-between">
            <p class="text-white/40 text-md">
              <.icon name="hero-user-group" class="h-6 w-6" /> {@live_viewer_count}
            </p>
            <.link navigate={"/now-playing/#{@exhibition.theater.slug}"}>
              <.button>
                Enter Theater →
              </.button>
            </.link>
          </div>
        </div>
      </div>
      <div class="text-center text-md mt-4 text-mystery-white">
        <span class="text-gray-400">Now playing</span>
        <span class="italic">{film.title}</span>
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
