defmodule TimesinkWeb.Cinema.ArchivesLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.Showcase

  def mount(_params, _session, socket) do
    showcases = Showcase.list_archived_showcases()
    {:ok, assign(socket, showcases: showcases)}
  end

  def render(assigns) do
    ~H"""
    <div class="archives-page px-6 py-10 max-w-6xl mx-auto">
      <h1 class="text-4xl font-semibold mb-2">Archives</h1>
      <p class="text-gray-400 text-sm mb-12 max-w-prose">
        A curated record of our past screenings, presented by theater and showcase.
      </p>

      <%= for {showcase, _idx} <- Enum.with_index(@showcases) do %>
        <div class="showcase mb-20 pb-10 border-b border-gray-800">
          <div class="mb-6">
            <h2 class="text-xl font-semibold text-gray-200 tracking-tight">{showcase.title}</h2>
            <p class="text-sm text-gray-500 italic">
              {format_showcase_dates(showcase.start_at, showcase.end_at)}
            </p>
          </div>

          <div class="flex flex-wrap gap-6">
            <%= for exhibition <- showcase.exhibitions do %>
              <.link navigate={}>
                <div class="film-card group hover:bg-gray-800/10 p-1 rounded transition w-[160px]">
                  <img
                    src={Timesink.Cinema.Film.poster_url(exhibition.film.poster)}
                    alt={exhibition.film.title}
                    class="aspect-square w-full object-cover rounded shadow-sm"
                  />
                  <div class="mt-2">
                    <h3 class="text-base font-semibold leading-tight group-hover:underline text-gray-100">
                      {exhibition.film.title}
                    </h3>
                    <div class="text-sm text-gray-400">{exhibition.film.year}</div>
                    <div class="text-sm text-gray-500">
                      Dir: {join_names(exhibition.film.directors)}
                    </div>
                    <div class="text-sm text-gray-500 italic truncate">
                      Cast: {join_names(exhibition.film.cast)}
                    </div>
                    <div class="text-xs text-gray-500 mt-1">
                      {exhibition.theater.name}
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp join_names([]), do: ""

  defp join_names(creatives) do
    creatives
    |> Enum.map(fn %{creative: c} -> "#{c.first_name} #{c.last_name}" end)
    |> Enum.join(", ")
  end

  defp format_showcase_dates(nil, nil), do: ""

  defp format_showcase_dates(start_at, nil) do
    "Started on " <> Calendar.strftime(start_at, "%B %d, %Y")
  end

  defp format_showcase_dates(nil, end_at) do
    "Ended on " <> Calendar.strftime(end_at, "%B %d, %Y")
  end

  defp format_showcase_dates(start_at, end_at) do
    if Calendar.strftime(start_at, "%B") == Calendar.strftime(end_at, "%B") do
      # Same month, e.g. "March 2–10, 2024"
      Calendar.strftime(start_at, "%B %-d") <>
        "–" <> Calendar.strftime(end_at, "%-d, %Y")
    else
      # Different month, e.g. "February 28 – March 5, 2024"
      Calendar.strftime(start_at, "%B %-d") <>
        " – " <> Calendar.strftime(end_at, "%B %-d, %Y")
    end
  end
end
