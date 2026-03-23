defmodule TimesinkWeb.Cinema.ArchivesLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.Showcase

  # ---------- MOUNT ----------
  def mount(_params, _session, socket) do
    showcases =
      Showcase.list_archived_showcases()
      |> Enum.sort_by(
        fn s -> normalize_datetime(s.end_at || s.start_at) end,
        {:desc, DateTime}
      )

    years =
      showcases
      |> Enum.flat_map(&extract_years/1)
      |> Enum.uniq()
      |> Enum.sort(:desc)

    theaters =
      showcases
      |> Enum.flat_map(fn sc -> Enum.map(sc.exhibitions, & &1.theater.name) end)
      |> Enum.uniq()
      |> Enum.sort()

    {:ok,
     socket
     |> assign(
       showcases: showcases,
       q: "",
       selected_year: "all",
       selected_theater: "all",
       years: years,
       theaters: theaters
     )
     |> assign_grouped()}
  end

  # ---------- EVENTS ----------
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(q: q) |> assign_grouped()}
  end

  def handle_event("filter-year", %{"year" => year}, socket) do
    {:noreply, socket |> assign(selected_year: year) |> assign_grouped()}
  end

  def handle_event("filter-theater", %{"theater" => th}, socket) do
    {:noreply, socket |> assign(selected_theater: th) |> assign_grouped()}
  end

  # ---------- RENDER ----------
  def render(assigns) do
    ~H"""
    <div class="archives-page relative">
      <header class="relative overflow-hidden">
        <div class="mx-auto max-w-7xl px-6 md:px-8 py-10 md:py-14">
          <div class="relative">
            <h1 class="text-2xl md:text-3xl tracking-tight text-mystery-white uppercase">Archives</h1>
            <p class="mt-2 text-sm md:text-base text-zinc-400">
              Past showcases, filmmakers, and cast preserved. View the unfolding story of TimeSink and the artists who've shaped it.
            </p>
          </div>
          
    <!-- Controls -->
          <!-- Controls -->
          <div class="mt-6 md:mt-8 grid grid-cols-1 md:grid-cols-3 gap-3">
            <!-- Search -->
            <div class="md:col-span-1">
              <form phx-change="search">
                <div class="relative">
                  <input
                    name="q"
                    value={@q}
                    placeholder="Search title, director, cast…"
                    phx-debounce="250"
                    class="h-12 w-full rounded-2xl border border-zinc-800 bg-[#0C0C0C] text-zinc-100 placeholder-zinc-500
                 focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                 px-4 pr-10"
                  />
                  <!-- trailing hint -->
                  <div class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs text-zinc-500">
                    ⌘K
                  </div>
                </div>
              </form>
            </div>
            
    <!-- Year -->
            <div>
              <form phx-change="filter-year">
                <div class="relative">
                  <select
                    name="year"
                    value={@selected_year}
                    class="h-12 w-full appearance-none rounded-2xl border border-zinc-800 bg-[#0C0C0C] text-zinc-100
                 focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                 px-4 pr-10"
                  >
                    <option value="all">All years</option>
                    <%= for y <- @years do %>
                      <option value={to_string(y)} selected={@selected_year == to_string(y)}>
                        {y}
                      </option>
                    <% end %>
                  </select>
                  <!-- custom chevron, perfectly centered -->
                  <svg
                    class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 10.172l3.71-2.94a.75.75 0 111.04 1.08l-4.24 3.36a.75.75 0 01-.94 0l-4.24-3.36a.75.75 0 01-.02-1.06z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </div>
              </form>
            </div>
            
    <!-- Theater -->
            <div>
              <form phx-change="filter-theater">
                <div class="relative">
                  <select
                    name="theater"
                    value={@selected_theater}
                    class="h-12 w-full appearance-none rounded-2xl border border-zinc-800 bg-[#0C0C0C] text-zinc-100
                 focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                 px-4 pr-10"
                  >
                    <option value="all">All theaters</option>
                    <%= for t <- @theaters do %>
                      <option value={t} selected={@selected_theater == t}>{t}</option>
                    <% end %>
                  </select>
                  <svg
                    class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 10.172l3.71-2.94a.75.75 0 111.04 1.08l-4.24 3.36a.75.75 0 01-.94 0l-4.24-3.36a.75.75 0 01-.02-1.06z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </div>
              </form>
            </div>
          </div>
        </div>
      </header>
      
    <!-- Content -->
      <div class="mx-auto max-w-7xl px-6 md:px-8 pb-20">
        <%= if Enum.empty?(@grouped) do %>
          <div class="mt-24 text-center text-zinc-400">No matches found.</div>
        <% end %>

        <%= for {year, groups} <- @grouped do %>
          <section id={"year-#{year}"} class="scroll-mt-24">
            <%= for group <- groups do %>
              <div class="mt-8">
                <div class="flex items-baseline justify-between mb-3">
                  <div>
                    <h3 class="text-lg font-semibold text-zinc-100">{group.title}</h3>
                    <p class="text-xs text-zinc-500">
                      {format_showcase_dates(group.start_at, group.end_at)}
                    </p>
                  </div>
                </div>
                
    <!-- Poster grid (square, non-interactive) -->
                <!-- Poster grid (square, hover effect, non-interactive) -->
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 md:gap-6">
                  <%= for ex <- group.exhibitions do %>
                    <.link navigate={"/films/#{ex.film.id}/#{TimesinkWeb.Cinema.FilmLive.title_slug(ex.film.title)}"}>
                      <article
                        class="group relative rounded-2xl overflow-hidden border border-zinc-800 bg-[#0C0C0C]
             transition-all duration-300 cursor-pointer select-none
             hover:border-dark-theater-primary/50"
                        aria-label={ex.film.title}
                      >
                        <div class="relative aspect-square w-full overflow-hidden">
                          <img
                            src={Timesink.Cinema.Film.poster_url(ex.film.poster)}
                            alt={ex.film.title}
                            loading="lazy"
                            class="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.03]"
                          />
                          <!-- subtle glow on hover -->
                          <div class="pointer-events-none absolute inset-0 opacity-0 group-hover:opacity-100 transition
                    bg-[radial-gradient(60%_50%_at_50%_50%,rgba(0,224,255,0.10),transparent)]">
                          </div>
                          
    <!-- theater pill -->
                          <div class="absolute left-2 top-2 rounded-full bg-black/70 backdrop-blur px-2 py-1
                    text-[10px] font-medium text-zinc-200 border border-zinc-700">
                            {ex.theater.name}
                          </div>
                        </div>

                        <div class="p-3">
                          <h4 class="line-clamp-1 text-sm font-semibold text-zinc-100">
                            {ex.film.title}
                          </h4>
                          <div class="mt-1 flex items-center gap-2 text-[11px] text-zinc-400">
                            <span>{ex.film.year}</span>
                            <span class="opacity-40">•</span>
                            <span class="line-clamp-1">Dir: {join_names(ex.film.directors)}</span>
                          </div>
                          <p class="mt-1 line-clamp-1 text-[11px] text-zinc-500">
                            Cast: {join_names(ex.film.cast)}
                          </p>
                        </div>
                      </article>
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  # ---------- ASSIGN & FILTER ----------
  defp assign_grouped(socket) do
    %{q: q, selected_year: y, selected_theater: th, showcases: showcases} = socket.assigns

    filtered =
      showcases
      |> Enum.filter(fn sc ->
        year_ok? = y == "all" or extract_showcase_year(sc) |> to_string() == y
        theater_ok? = th == "all" or Enum.any?(sc.exhibitions, fn ex -> ex.theater.name == th end)
        search_ok? = q == "" or showcase_matches?(sc, q)
        year_ok? and theater_ok? and search_ok?
      end)

    grouped =
      filtered
      |> Enum.group_by(&extract_showcase_year/1)
      |> Enum.sort_by(fn {year, _} -> year end, :desc)
      |> Enum.map(fn {year, scs} ->
        {
          year,
          Enum.map(scs, fn sc ->
            %{
              id: sc.id,
              title: sc.title,
              start_at: sc.start_at,
              end_at: sc.end_at,
              exhibitions: sc.exhibitions
            }
          end)
        }
      end)

    assign(socket, grouped: grouped)
  end

  defp showcase_matches?(sc, q) do
    needle = String.downcase(q)

    within_exhibitions? =
      Enum.any?(sc.exhibitions, fn ex ->
        t = String.downcase(ex.film.title || "")
        d = String.downcase(join_names(ex.film.directors))
        c = String.downcase(join_names(ex.film.cast))
        String.contains?(t, needle) or String.contains?(d, needle) or String.contains?(c, needle)
      end)

    in_title? = String.contains?(String.downcase(sc.title || ""), needle)
    within_exhibitions? or in_title?
  end

  # ---------- HELPERS ----------
  defp join_names(nil), do: ""
  defp join_names([]), do: ""

  defp join_names(creatives) do
    creatives
    |> Enum.map(fn
      %{creative: c} -> Enum.join([c.first_name, c.last_name] |> Enum.reject(&is_nil/1), " ")
      %{first_name: f, last_name: l} -> Enum.join([f, l] |> Enum.reject(&is_nil/1), " ")
      other when is_binary(other) -> other
      _ -> ""
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end

  defp extract_years(sc) do
    [sc.start_at, sc.end_at]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(& &1.year)
  end

  defp extract_showcase_year(%{end_at: %DateTime{year: y}}), do: y
  defp extract_showcase_year(%{start_at: %DateTime{year: y}}), do: y
  defp extract_showcase_year(_), do: 1970

  # Kept for future use if you add links back
  # defp build_film_link(exhibition) do
  #   cond do
  #     Map.get(exhibition.film, :slug) -> ~p"/films/#{exhibition.film.slug}"
  #     Map.get(exhibition.film, :id) -> ~p"/films/#{exhibition.film.id}"
  #     true -> "#"
  #   end
  # end

  defp format_showcase_dates(nil, nil), do: ""

  defp format_showcase_dates(start_at, nil),
    do: "Started on " <> Calendar.strftime(start_at, "%B %d, %Y")

  defp format_showcase_dates(nil, end_at),
    do: "Ended on " <> Calendar.strftime(end_at, "%B %d, %Y")

  defp format_showcase_dates(start_at, end_at) do
    if Calendar.strftime(start_at, "%B") == Calendar.strftime(end_at, "%B") do
      Calendar.strftime(start_at, "%B %-d") <> "–" <> Calendar.strftime(end_at, "%-d, %Y")
    else
      Calendar.strftime(start_at, "%B %-d") <> " – " <> Calendar.strftime(end_at, "%B %-d, %Y")
    end
  end

  defp normalize_datetime(nil), do: ~U[1970-01-01 00:00:00Z]
  defp normalize_datetime(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")
  defp normalize_datetime(%DateTime{} = dt), do: dt
end
