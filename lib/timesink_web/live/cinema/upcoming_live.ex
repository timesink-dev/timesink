defmodule TimesinkWeb.Cinema.UpcomingLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.Showcase

  @tick_ms 1_000

  # ---------- MOUNT ----------
  def mount(_params, _session, socket) do
    upcoming =
      Showcase.list_upcoming_showcases()
      |> Enum.sort_by(
        fn s -> normalize_datetime(s.start_at || s.end_at) end,
        {:asc, DateTime}
      )

    months =
      upcoming
      |> Enum.flat_map(&extract_month_tags/1)
      |> Enum.uniq()
      |> Enum.sort()

    theaters =
      upcoming
      |> Enum.flat_map(fn sc -> Enum.map(sc.exhibitions, & &1.theater.name) end)
      |> Enum.uniq()
      |> Enum.sort()

    if connected?(socket), do: :timer.send_interval(@tick_ms, self(), :tick)

    {:ok,
     socket
     |> assign(
       upcoming: upcoming,
       now: DateTime.utc_now(),
       q: "",
       selected_month: "all",
       selected_theater: "all",
       months: months,
       theaters: theaters
     )
     |> assign_grouped()}
  end

  # ---------- EVENTS ----------
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(q: q) |> assign_grouped()}
  end

  def handle_event("filter-month", %{"month" => m}, socket) do
    {:noreply, socket |> assign(selected_month: m) |> assign_grouped()}
  end

  def handle_event("filter-theater", %{"theater" => th}, socket) do
    {:noreply, socket |> assign(selected_theater: th) |> assign_grouped()}
  end

  # live countdown tick
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  # ---------- RENDER ----------
  def render(assigns) do
    ~H"""
    <div class="upcoming-page relative">
      <header class="relative overflow-hidden">
        <div class="mx-auto max-w-7xl px-6 md:px-8 py-10 md:py-14">
          <div class="relative">
            <h1 class="text-2xl md:text-3xl tracking-tight text-mystery-white uppercase">Upcoming</h1>
            <p class="mt-2 text-sm md:text-base text-zinc-400">
              New showcases on the horizon.
            </p>
          </div>
          
    <!-- Controls -->
          <div
            id="upcoming-controls"
            phx-update="ignore"
            class="mt-6 md:mt-8 grid grid-cols-1 md:grid-cols-3 gap-3"
          >
            <!-- Search -->
            <div class="md:col-span-1">
              <form phx-change="search">
                <div class="relative">
                  <input
                    name="q"
                    value={@q}
                    placeholder="Search title, director, cast…"
                    phx-debounce="250"
                    class="h-12 w-full rounded-2xl border border-zinc-800 bg-backroom-black text-zinc-100 placeholder-zinc-500
                           focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                           px-4 pr-10"
                  />
                  <div class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs text-zinc-500">
                    ⌘K
                  </div>
                </div>
              </form>
            </div>
            
    <!-- Month -->
            <div>
              <form phx-change="filter-month">
                <div class="relative">
                  <select
                    name="month"
                    value={@selected_month}
                    class="h-12 w-full appearance-none rounded-2xl border border-zinc-800 bg-[#0C0C0C] text-zinc-100
                           focus:outline-none focus:ring-1 focus:ring-neon-blue-light focus:border-neon-blue-light
                           px-4 pr-10"
                  >
                    <option value="all">All months</option>
                    <%= for m <- @months do %>
                      <option value={m} selected={@selected_month == m}>{m}</option>
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
          <div class="mt-24 text-center text-zinc-400">No upcoming exhibitions found.</div>
        <% end %>

        <%= for {month_tag, groups} <- @grouped do %>
          <section id={"m-#{month_tag}"} class="scroll-mt-24 mt-16 md:mt-20">
            <div class="sticky top-0 z-10 -mx-6 md:-mx-8
              bg-gradient-to-r from-white/[0.08] to-white/[0.08]">
              <div class="px-6 md:px-8 py-4 flex items-center justify-between">
                <h2 class="text-sm tracking-widest uppercase text-mystery-white">{month_tag}</h2>
              </div>
            </div>

            <div class="mb-8"></div>
            <!-- extra gap after the sticky banner -->

            <%= for group <- groups do %>
              <div class="mt-8">
                <div class="flex items-baseline justify-between mb-3">
                  <div>
                    <h3 class="text-lg font-semibold text-zinc-100">{group.title}</h3>
                    <p class="text-xs text-zinc-500">
                      Premieres {format_premiere_date(group.start_at)}
                      <%= if group.end_at do %>
                        <span class="opacity-40">•</span>
                        Runs until {Calendar.strftime(group.end_at, "%B %-d, %Y")}
                      <% end %>
                    </p>
                  </div>
                </div>
                
    <!-- Poster grid (square, hover alive, not clickable) -->
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 md:gap-6">
                  <%= for ex <- group.exhibitions do %>
                    <article
                      class="group relative rounded-2xl overflow-hidden border border-zinc-800 bg-[#0C0C0C]
                             transition-all duration-300 cursor-default select-none
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
                        
    <!-- cinema ribbon: "Premieres" -->
                        <div class="absolute left-2 top-2 rounded
            bg-neon-blue-lightest text-backroom-black
            px-2 py-1 text-[10px] font-semibold
            ring-neon-blue-lightest shadow-sm">
                          Premieres {format_short_date(group.start_at)}
                        </div>
                        
    <!-- subtle glow -->
                        <div class="pointer-events-none absolute inset-0 opacity-0 group-hover:opacity-100 transition
                                    bg-[radial-gradient(60%_50%_at_50%_50%,rgba(0,224,255,0.10),transparent)]">
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
                        
    <!-- countdown -->
                        <%= if group.start_at do %>
                          <div class="mt-2 text-[11px] font-medium text-zinc-300">
                            Starts in {format_countdown(@now, group.start_at)}
                          </div>
                        <% end %>
                      </div>
                    </article>
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
    %{
      q: q,
      selected_month: m,
      selected_theater: th,
      upcoming: upcoming
    } = socket.assigns

    filtered =
      upcoming
      |> Enum.filter(fn sc ->
        month_ok? = m == "all" or month_tag(sc.start_at || sc.end_at) == m
        theater_ok? = th == "all" or Enum.any?(sc.exhibitions, fn ex -> ex.theater.name == th end)
        search_ok? = q == "" or showcase_matches?(sc, q)
        month_ok? and theater_ok? and search_ok?
      end)

    grouped =
      filtered
      |> Enum.group_by(fn sc -> month_tag(sc.start_at || sc.end_at) end)
      |> Enum.sort_by(fn {tag, _} -> month_sort_key(tag) end, :asc)
      |> Enum.map(fn {tag, scs} ->
        {
          tag,
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

    in_title? = String.contains?(String.downcase(sc.title || ""), needle)

    within_exhibitions? =
      Enum.any?(sc.exhibitions, fn ex ->
        t = String.downcase(ex.film.title || "")
        d = String.downcase(join_names(ex.film.directors))
        c = String.downcase(join_names(ex.film.cast))
        String.contains?(t, needle) or String.contains?(d, needle) or String.contains?(c, needle)
      end)

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

  defp extract_month_tags(sc) do
    [sc.start_at, sc.end_at]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&month_tag/1)
  end

  defp month_tag(nil), do: "TBD"
  defp month_tag(%DateTime{} = dt), do: Calendar.strftime(dt, "%B %Y")

  defp month_tag(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> Calendar.strftime("%B %Y")

  # stable sort key for "Month YYYY"
  defp month_sort_key("TBD"), do: {9999, 12}

  defp month_sort_key(tag) do
    # e.g., "March 2026" -> {2026, 03}
    [mname, year] = String.split(tag, " ")
    {String.to_integer(year), month_number(mname)}
  end

  defp month_number(name) do
    ~w(January February March April May June July August September October November December)
    |> Enum.find_index(&(&1 == name))
    |> Kernel.+(1)
  end

  defp format_premiere_date(nil), do: "TBD"

  defp format_premiere_date(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> Calendar.strftime("%B %-d, %Y")

  defp format_premiere_date(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%B %-d, %Y")

  defp format_short_date(nil), do: "TBD"

  defp format_short_date(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> Calendar.strftime("%b %-d")

  defp format_short_date(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%b %-d")

  # Countdown like "2d 04:12:09" (floors at zero)
  defp format_countdown(_now, nil), do: "TBD"

  defp format_countdown(%DateTime{} = now, %NaiveDateTime{} = ndt),
    do: format_countdown(now, DateTime.from_naive!(ndt, "Etc/UTC"))

  defp format_countdown(%DateTime{} = now, %DateTime{} = start_at) do
    diff = max(DateTime.diff(start_at, now, :second), 0)
    days = div(diff, 86_400)
    rem1 = rem(diff, 86_400)
    hours = div(rem1, 3600)
    rem2 = rem(rem1, 3600)
    mins = div(rem2, 60)
    secs = rem(rem2, 60)
    day_part = if days > 0, do: "#{days}d ", else: ""

    :io_lib.format("~s~2..0B:~2..0B:~2..0B", [day_part, hours, mins, secs])
    |> IO.iodata_to_binary()
  end

  defp normalize_datetime(nil), do: ~U[1970-01-01 00:00:00Z]
  defp normalize_datetime(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")
  defp normalize_datetime(%DateTime{} = dt), do: dt
end
