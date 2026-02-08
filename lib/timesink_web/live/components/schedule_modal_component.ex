defmodule TimesinkWeb.ScheduleModalComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Cinema.Film
  alias TimesinkWeb.PubSubTopics

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="schedule-modal">
        <%= cond do %>
          <% @showcase -> %>
            <div class="space-y-6">
              <!-- Header -->
              <div class="border-b border-white/10 pb-6">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-2">
                      <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-0.5 text-xs font-medium text-emerald-400">
                        <div class="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse"></div>
                        Live Now
                      </span>
                      <span class="text-xs text-zinc-500">
                        {format_date_range(@showcase.start_at, @showcase.end_at, @timezone)}
                      </span>
                    </div>
                    <div class="mt-4.5">
                      <h3 class="text-sm font-medium text-white uppercase tracking-wider mb-1">
                        Showcase
                      </h3>
                      <h2 id="schedule-modal-title" class="text-xl font-semibold text-white">
                        {@showcase.title}
                      </h2>
                      <p class="mt-2 text-sm text-zinc-400 leading-relaxed">
                        {@showcase.description}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Continuous Screening Info -->
              <div class="rounded-xl border border-white/10 bg-linear-to-br from-white/3 to-white/1 p-4">
                <div class="flex items-start gap-3">
                  <div class="shrink-0 mt-0.5">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5 text-neon-blue-lightest"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                    >
                      <path d="M12 2a10 10 0 1 1 0 20A10 10 0 0 1 12 2Zm1 5h-2v6l5 3 .9-1.79L13 12.5V7Z" />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <h3 class="text-sm font-medium text-white">Continuous Screenings</h3>
                    <p class="mt-1 text-xs text-zinc-400 leading-relaxed">
                      Films play in rotation across all theaters. Each screening begins every 15 minutes during the showcase period.
                    </p>
                  </div>
                </div>
              </div>
              
    <!-- Films in Rotation -->
              <div>
                <h3 class="text-sm font-medium text-white uppercase tracking-wider mb-4">
                  Now Screening ({length(@exhibitions)} {if length(@exhibitions) == 1,
                    do: "Film",
                    else: "Films"})
                </h3>

                <div class="space-y-3 max-h-96 overflow-y-auto pr-2">
                  <%= for exhibition <- @exhibitions do %>
                    <div class="group rounded-xl border border-white/10 bg-linear-to-r from-white/2 to-transparent hover:border-white/20 hover:from-white/4 transition-all">
                      <.link navigate={"/now-playing/#{exhibition.theater.slug}"}>
                        <div class="flex gap-4 p-4">
                          <!-- Poster -->
                          <div class="shrink-0">
                            <img
                              src={Film.poster_url(exhibition.film.poster)}
                              alt={exhibition.film.title}
                              class="w-16 h-24 object-cover rounded-lg ring-1 ring-white/10"
                            />
                          </div>
                          
    <!-- Film Info -->
                          <div class="flex-1 min-w-0">
                            <div class="flex items-start justify-between gap-3">
                              <div class="flex-1 min-w-0">
                                <h4 class="text-base font-medium text-white truncate">
                                  {exhibition.film.title}
                                </h4>
                                <div class="flex items-center gap-2 mt-1 text-xs text-zinc-400">
                                  <span>{exhibition.theater.name}</span>
                                  <span class="text-zinc-600">•</span>
                                  <span>{exhibition.film.duration} min</span>
                                  <%= if exhibition.film.year do %>
                                    <span class="text-zinc-600">•</span>
                                    <span>{exhibition.film.year}</span>
                                  <% end %>
                                </div>
                              </div>
                              
    <!-- Live Status Badge -->
                              <div class="shrink-0">
                                <%= case get_playback_phase(exhibition.theater_id, @playback_states) do %>
                                  <% :playing -> %>
                                    <span class="inline-flex items-center gap-1.5 rounded-full bg-red-500/10 border border-red-500/20 px-2.5 py-1 text-xs font-medium text-red-400">
                                      <div class="h-1.5 w-1.5 rounded-full bg-red-400 animate-pulse">
                                      </div>
                                      Playing
                                    </span>
                                  <% :intermission -> %>
                                    <span class="inline-flex items-center rounded-full bg-amber-500/10 border border-amber-500/20 px-2.5 py-1 text-xs font-medium text-amber-400">
                                      Intermission
                                    </span>
                                  <% :upcoming -> %>
                                    <span class="inline-flex items-center rounded-full bg-blue-500/10 border border-blue-500/20 px-2.5 py-1 text-xs font-medium text-blue-400">
                                      Starting Soon
                                    </span>
                                  <% _ -> %>
                                    <span class="inline-flex items-center rounded-full bg-zinc-500/10 border border-zinc-500/20 px-2.5 py-1 text-xs font-medium text-zinc-400">
                                      Scheduled
                                    </span>
                                <% end %>
                              </div>
                            </div>
                            
    <!-- Viewer Count -->
                            <div class="flex items-center gap-4 mt-3">
                              <div class="flex items-center gap-1.5 text-xs text-zinc-500">
                                <.icon name="hero-user-group" class="h-4 w-4" />
                                <span>
                                  {live_viewer_count(exhibition.theater_id, @presence)}
                                  {if live_viewer_count(exhibition.theater_id, @presence) == 1,
                                    do: "viewer",
                                    else: "viewers"}
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </.link>
                    </div>
                  <% end %>
                </div>
              </div>
              
    <!-- Footer Note -->
              <div class="border-t border-white/10 pt-4">
                <p class="text-xs text-zinc-500 text-center">
                  All times displayed in your local timezone ({@timezone})
                </p>
              </div>
            </div>
          <% @upcoming_showcase -> %>
            <div class="space-y-6">
              <div class="border-b border-white/10 pb-6">
                <div class="flex items-center gap-2 mb-2">
                  <span class="inline-flex items-center gap-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 px-2.5 py-0.5 text-xs font-medium text-blue-300">
                    <div class="h-1.5 w-1.5 rounded-full bg-blue-300 animate-pulse"></div>
                    Next Up
                  </span>
                  <span class="text-xs text-zinc-500">No showcase is live right now</span>
                </div>

                <div class="mt-4.5">
                  <h3 class="text-sm font-medium text-white uppercase tracking-wider mb-1">
                    Upcoming Showcase
                  </h3>
                  <h2 class="text-xl font-semibold text-white">
                    {@upcoming_showcase.title}
                  </h2>
                  <p class="mt-2 text-sm text-zinc-400 leading-relaxed">
                    {@upcoming_showcase.description}
                  </p>

                  <div class="mt-4 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-3 py-1">
                    <span class="text-xs uppercase tracking-wider text-zinc-400">Starts</span>
                    <span class="text-sm font-medium text-white">
                      {Calendar.strftime(@upcoming_showcase.start_at, "%A, %B %d · %H:%M")}
                    </span>
                    <span class="text-xs text-zinc-500">({@timezone})</span>
                  </div>
                </div>
              </div>

              <div class="rounded-xl border border-white/10 bg-linear-to-br from-white/3 to-white/[0.01] p-4">
                <p class="text-sm text-zinc-400">
                  The lineup will appear here once the doors open. Come back closer to start time.
                </p>
              </div>

              <div class="border-t border-white/10 pt-4">
                <p class="text-xs text-zinc-500 text-center">
                  All times displayed in your local timezone ({@timezone})
                </p>
              </div>
            </div>
          <% true -> %>
            <!-- ✅ NO SHOWCASE AT ALL -->
            <div class="space-y-6">
              <div class="border-b border-white/10 pb-6">
                <h2 class="text-xl font-semibold text-white">No Showcase Scheduled</h2>
                <p class="mt-2 text-sm text-zinc-400 leading-relaxed">
                  We’re curating the next drop. Check back soon.
                </p>
              </div>

              <div class="rounded-xl border border-white/10 bg-linear-to-br from-white/3 to-white/1 p-4">
                <p class="text-sm text-zinc-400">
                  Want a heads-up when the next showcase is announced?
                </p>
                <div class="mt-4">
                  <.link
                    navigate="/waitlist"
                    class="inline-flex items-center justify-center rounded-full bg-white text-backroom-black px-4.5 py-2 text-sm font-medium transition hover:opacity-90"
                  >
                    Get notified
                  </.link>
                </div>
              </div>

              <div class="border-t border-white/10 pt-4">
                <p class="text-xs text-zinc-500 text-center">
                  All times displayed in your local timezone ({@timezone})
                </p>
              </div>
            </div>
        <% end %>
      </.modal>
    </div>
    """
  end

  defp live_viewer_count(theater_id, presence) do
    topic = PubSubTopics.presence_topic(theater_id)
    Map.get(presence, topic, %{}) |> map_size()
  end

  defp get_playback_phase(theater_id, playback_states) do
    case Map.get(playback_states, to_string(theater_id)) do
      %{phase: phase} -> phase
      _ -> nil
    end
  end

  defp format_date_range(start_at, end_at, timezone) do
    start_dt =
      start_at
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.shift_zone!(timezone)

    end_dt =
      end_at
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.shift_zone!(timezone)

    start_str = Calendar.strftime(start_dt, "%b %d")
    end_str = Calendar.strftime(end_dt, "%b %d, %Y")

    "#{start_str} - #{end_str}"
  end
end
