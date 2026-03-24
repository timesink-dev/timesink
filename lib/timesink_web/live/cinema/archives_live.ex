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
       theaters: theaters,
       creative_results: [],
       film_results: []
     )
     |> assign_grouped()}
  end

  # ---------- EVENTS ----------
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(q: q) |> assign_grouped() |> assign_search_results()}
  end

  def handle_event("filter-year", %{"year" => year}, socket) do
    {:noreply,
     socket |> assign(selected_year: year) |> assign_grouped() |> assign_search_results()}
  end

  def handle_event("filter-theater", %{"theater" => th}, socket) do
    {:noreply,
     socket |> assign(selected_theater: th) |> assign_grouped() |> assign_search_results()}
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
                <div id="archives-search-wrapper" phx-update="ignore">
                  <div class="relative">
                    <input
                      id="archives-search"
                      name="q"
                      value=""
                      placeholder="Search title, director, cast…"
                      phx-debounce="250"
                      phx-hook="SearchFocus"
                      autocomplete="off"
                      class="h-12 w-full rounded-2xl border border-zinc-800 bg-[#0C0C0C] text-zinc-100 placeholder-zinc-500
                   focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                   px-4 pr-10"
                    />
                    <div class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs text-zinc-500">
                      ⌘K
                    </div>
                  </div>
                </div>
              </form>
              <!-- Search results panel -->
              <%= if @q != "" do %>
                <div class="mt-2 rounded-xl border border-zinc-800 bg-[#0C0C0C] overflow-hidden">
                  <%= if Enum.empty?(@film_results) and Enum.empty?(@creative_results) do %>
                    <p class="px-4 py-3 text-xs text-zinc-500">No results found.</p>
                  <% else %>
                    <%= if not Enum.empty?(@film_results) do %>
                      <p class="px-4 pt-3 pb-1 text-[10px] uppercase tracking-widest text-zinc-600">
                        Films
                      </p>
                      <ul class="divide-y divide-zinc-800/60">
                        <%= for film <- @film_results do %>
                          <li class="group/row relative px-4 py-2.5 hover:bg-zinc-800/30 transition-colors">
                            <.link
                              navigate={"/films/#{film.id}/#{TimesinkWeb.Cinema.FilmLive.title_slug(film.title)}"}
                              class="absolute inset-0"
                              aria-hidden="true"
                            >
                              <span />
                            </.link>
                            <div class="relative pointer-events-none flex items-center justify-between">
                              <div>
                                <span class="text-sm text-zinc-100">{film.title}</span>
                                <span class="ml-2 text-[11px] text-zinc-500">{film.year}</span>
                                <%= if film.directors != "" do %>
                                  <p class="text-[11px] text-zinc-600 mt-0.5">
                                    Dir: {film.directors}
                                  </p>
                                <% end %>
                              </div>
                              <svg
                                class="h-3.5 w-3.5 text-zinc-500 group-hover/row:text-zinc-300 transition-colors shrink-0"
                                viewBox="0 0 16 16"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  d="M3 8h10M9 4l4 4-4 4"
                                />
                              </svg>
                            </div>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                    <%= if not Enum.empty?(@creative_results) do %>
                      <p class="px-4 pt-3 pb-1 text-[10px] uppercase tracking-widest text-zinc-600">
                        Filmmakers
                      </p>
                      <ul class="divide-y divide-zinc-800/60">
                        <%= for c <- @creative_results do %>
                          <li class="group/row relative px-4 py-3 hover:bg-zinc-800/30 transition-colors">
                            <.link
                              navigate={creative_link(c)}
                              class="absolute inset-0"
                              aria-hidden="true"
                            >
                              <span />
                            </.link>
                            <div class="relative pointer-events-none flex items-center justify-between mb-1">
                              <div class="flex items-baseline gap-2">
                                <span class="text-sm font-medium text-zinc-100">
                                  {c.first_name} {c.last_name}
                                </span>
                                <span class="text-[10px] text-zinc-500 capitalize">
                                  {c.primary_role}
                                </span>
                              </div>
                              <svg
                                class="h-3.5 w-3.5 text-zinc-500 group-hover/row:text-zinc-300 transition-colors shrink-0"
                                viewBox="0 0 16 16"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  d="M3 8h10M9 4l4 4-4 4"
                                />
                              </svg>
                            </div>
                            <div class="relative flex flex-wrap gap-1 mt-1">
                              <%= for film <- c.films do %>
                                <.link
                                  navigate={"/films/#{film.id}/#{TimesinkWeb.Cinema.FilmLive.title_slug(film.title)}"}
                                  class="text-[11px] text-zinc-400 hover:text-zinc-200 transition-colors bg-zinc-800/60 rounded px-2 py-0.5 pointer-events-auto"
                                >
                                  {film.title} <span class="text-zinc-600">({film.year})</span>
                                </.link>
                              <% end %>
                            </div>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
            
    <!-- Year -->
            <div id="archives-year-filter" phx-update="ignore">
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
            <div id="archives-theater-filter" phx-update="ignore">
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
            visible_exhibitions =
              if th == "all",
                do: sc.exhibitions,
                else: Enum.filter(sc.exhibitions, fn ex -> ex.theater.name == th end)

            %{
              id: sc.id,
              title: sc.title,
              start_at: sc.start_at,
              end_at: sc.end_at,
              exhibitions: visible_exhibitions
            }
          end)
          |> Enum.reject(fn g -> Enum.empty?(g.exhibitions) end)
        }
      end)
      |> Enum.reject(fn {_year, groups} -> Enum.empty?(groups) end)

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
  defp extract_showcase_year(%{end_at: %NaiveDateTime{year: y}}), do: y
  defp extract_showcase_year(%{start_at: %DateTime{year: y}}), do: y
  defp extract_showcase_year(%{start_at: %NaiveDateTime{year: y}}), do: y
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
  defp format_showcase_dates(start_at, nil), do: format_dmy(start_at)
  defp format_showcase_dates(nil, end_at), do: format_dmy(end_at)

  defp format_showcase_dates(start_at, end_at) do
    format_dmy(start_at) <> " – " <> format_dmy(end_at)
  end

  defp format_dmy(nil), do: "TBD"
  defp format_dmy(%NaiveDateTime{} = ndt), do: Calendar.strftime(ndt, "%d.%m.%y")
  defp format_dmy(%DateTime{} = dt), do: Calendar.strftime(dt, "%d.%m.%y")

  defp normalize_datetime(nil), do: ~U[1970-01-01 00:00:00Z]
  defp normalize_datetime(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")
  defp normalize_datetime(%DateTime{} = dt), do: dt

  # ---------- SEARCH RESULTS ----------
  defp assign_search_results(socket) do
    q = socket.assigns.q
    grouped = socket.assigns.grouped

    if q == "" do
      assign(socket, creative_results: [], film_results: [])
    else
      needle = String.downcase(q)

      all_films =
        grouped
        |> Enum.flat_map(fn {_tag, groups} ->
          Enum.flat_map(groups, fn group -> group.exhibitions end)
        end)
        |> Enum.map(fn ex -> ex.film end)
        |> Enum.uniq_by(& &1.id)

      all_pairs =
        Enum.flat_map(all_films, fn film ->
          film |> all_film_creatives() |> Enum.map(fn fc -> {fc, film} end)
        end)

      film_results =
        all_films
        |> Enum.filter(fn film ->
          String.contains?(String.downcase(film.title || ""), needle)
        end)
        |> Enum.sort_by(& &1.title)
        |> Enum.map(fn film ->
          %{
            id: film.id,
            title: film.title,
            year: film.year,
            directors: join_names(film.directors)
          }
        end)

      creative_results =
        all_pairs
        |> Enum.filter(fn {fc, _} ->
          name = String.downcase("#{fc.creative.first_name} #{fc.creative.last_name}")
          String.contains?(name, needle)
        end)
        |> Enum.group_by(fn {fc, _} -> fc.creative.id end)
        |> Enum.map(fn {_cid, pairs} ->
          {fc, _} = hd(pairs)

          films =
            pairs
            |> Enum.map(fn {_, film} -> %{id: film.id, title: film.title, year: film.year} end)
            |> Enum.uniq_by(& &1.id)
            |> Enum.sort_by(& &1.title)

          %{
            id: fc.creative.id,
            first_name: fc.creative.first_name,
            last_name: fc.creative.last_name,
            user: fc.creative.user,
            primary_role: fc.role,
            films: films
          }
        end)
        |> Enum.sort_by(fn c -> "#{c.last_name} #{c.first_name}" end)

      assign(socket, creative_results: creative_results, film_results: film_results)
    end
  end

  defp all_film_creatives(film) do
    (film.directors || []) ++
      (film.writers || []) ++
      (film.producers || []) ++
      (film.cast || []) ++
      (film.crew || [])
  end

  defp creative_link(%{user: %{username: username}}) when not is_nil(username),
    do: "/@#{username}"

  defp creative_link(%{id: id}), do: "/creatives/#{id}"
end
