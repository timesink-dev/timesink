defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics, ScheduleModalComponent}
  import TimesinkWeb.Components.{Hero, NoShowcase}

  def mount(_params, _session, socket) do
    # Capture timezone from browser (defaults to UTC if not provided)
    timezone = get_connect_params(socket)["timezone"] || "Etc/UTC"

    with showcase when not is_nil(showcase) <- Cinema.get_active_showcase_with_exhibitions() do
      exhibitions =
        (showcase.exhibitions || [])
        |> Cinema.preload_exhibitions()
        |> Enum.sort_by(& &1.theater.name, :asc)

      playback_states = Timesink.Cinema.compute_initial_playback_states(exhibitions, showcase)

      socket =
        assign(socket,
          showcase: showcase,
          exhibitions: exhibitions,
          playback_states: playback_states,
          presence: %{},
          upcoming_showcase: nil,
          no_showcase: false,
          timezone: timezone
        )

      if connected?(socket), do: send(self(), :connected)
      {:ok, socket}
    else
      nil ->
        case Cinema.get_upcoming_showcase() do
          %{} = upcoming ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: upcoming,
               no_showcase: false,
               timezone: timezone
             )}

          nil ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: nil,
               no_showcase: true,
               timezone: timezone
             )}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div id="homepage">
      <div
        id="hero"
        class="h-screen relative w-full bg-backroom-black text-white flex items-center justify-center"
      >
        <.hero />
      </div>

      <div
        id="cinema-barrier"
        class={["w-full", if(@upcoming_showcase, do: "h-6", else: "h-16")]}
        phx-hook="ScrollObserver"
      />

      <div id="bridge" class="relative isolate">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12 md:py-16">
          <!-- value proposition -->
          <div class="text-center mb-10">
            <h2 class="text-2xl md:text-3xl font-semibold tracking-tight">
              Cinema is live again. <br />
              <span class="ml-6">
                No algorithms, no noise. Just the way it should be.
              </span>
            </h2>
            <p class="mt-3 text-balance text-base md:text-lg text-zinc-400">
              Watch together. Chat live. Discover voices and films you won’t find on the multiplex billboard.
            </p>
            <%!--
            <%= if @spots_left do %>
              <p class="mt-4 inline-flex items-center gap-2 rounded-full border border-emerald-500/40 bg-emerald-500/10 px-3 py-1 text-sm text-emerald-300">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M12 2a10 10 0 1 1 0 20A10 10 0 0 1 12 2Zm1 5h-2v6l5 3 .9-1.79L13 12.5V7Z" />
                </svg>
                Only {@spots_left} spots left in this wave
              </p>
            <% end %> --%>
          </div>
          
    <!-- 3 column highlights -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
            <button
              type="button"
              phx-click={show_modal("lineup-info-modal")}
              class="group rounded-2xl border border-white/10 bg-white/2 p-5 text-left transition hover:border-white/20 hover:bg-white/3 cursor-pointer"
            >
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/6">
                <!-- film icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M4 4h4v4H4V4Zm6 0h4v4h-4V4Zm6 0h4v4h-4V4ZM4 10h16v10H4V10Zm0 6h4v4H4v-4Zm12 0h4v4h-4v-4Z" />
                </svg>
              </div>
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="text-lg font-medium">Hand-picked lineup</h3>
                  <p class="mt-1 text-sm text-zinc-400">
                    Spotlight on retrospectives, festival favorites, hidden gems, and filmmaker premieres.
                  </p>
                </div>
              </div>
            </button>

            <button
              type="button"
              phx-click={show_modal("live-info-modal")}
              class="group rounded-2xl border border-white/10 bg-white/2 p-5 text-left transition hover:border-white/20 hover:bg-white/3 cursor-pointer"
            >
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/6">
                <!-- chat icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2Z" />
                </svg>
              </div>
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="text-lg font-medium">Live for every showing</h3>
                  <p class="mt-1 text-sm text-zinc-400">
                    Live chats to engage with real people, not noisy comment walls.
                  </p>
                </div>
              </div>
            </button>

            <button
              type="button"
              phx-click={show_modal("community-info-modal")}
              class="group rounded-2xl border border-white/10 bg-white/2 p-5 text-left transition hover:border-white/20 hover:bg-white/3 cursor-pointer"
            >
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/6">
                <!-- globe icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm6.93 6h-3.26a14.6 14.6 0 0 0-2.01-4.2A8.03 8.03 0 0 1 18.93 8ZM12 4.06c.9 1.17 1.67 2.67 2.2 3.94H9.8c.53-1.27 1.3-2.77 2.2-3.94ZM5.07 8h3.26c.34-1.02.8-2.07 1.34-3.02A8.03 8.03 0 0 0 5.07 8Zm0 8a8.03 8.03 0 0 1 4.6 3.02A14.6 14.6 0 0 1 8.33 16H5.07Zm4.73 0h4.4c-.53 1.27-1.3 2.77-2.2 3.94-.9-1.17-1.67 2.67-2.2-3.94Zm8.13 0h-3.26c-.34 1.02-.8 2.07-1.34 3.02A8.03 8.03 0 0 0 17.93 16Zm-1.6-6c.27.96.45 2 .5 3.05H7.17c.05-1.05.23-2.09.5-3.05h8.66Z" />
                </svg>
              </div>
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="text-lg font-medium">Global community</h3>
                  <p class="mt-1 text-sm text-zinc-400">
                    Join a network of viewers from everywhere. Discover, discuss, connect, repeat.
                  </p>
                </div>
              </div>
            </button>
          </div>
          
    <!-- slim schedule teaser -->
          <div class="mt-10 rounded-2xl border border-white/10 bg-linear-to-r from-white/3 to-white/1 p-5">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <p class="text-sm uppercase tracking-wider text-zinc-400">This Week</p>
                <h4 class="mt-1 text-lg font-medium">Upcoming screenings &amp; special events</h4>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <div class="inline-flex items-center gap-2 rounded-full bg-white/6 px-3 py-1">
                  <div class="h-2 w-2 shrink-0 rounded-full bg-neon-red-light animate-pulse ring-1 ring-neon-red-light/40">
                  </div>
                  Live showings every 15 minutes
                </div>
                <button
                  phx-click={show_modal("schedule-modal")}
                  class="rounded border border-white/15 px-4.5 py-2 transition-all cursor-pointer hover:bg-white/6 hover:border-white/25"
                >
                  View schedule
                </button>
              </div>
            </div>
            <div class="mt-4 flex flex-wrap gap-2 text-sm">
              No events yet...
            </div>
            
    <!-- pills-style schedule items (demo preview) -->
            <%!-- <div class="mt-4 flex flex-wrap gap-2">
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Thu 19:00 — <span class="text-zinc-200">*Fragments of a City*</span> (Premiere)
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Fri 21:00 — <span class="text-zinc-200">*Electric Gardens*</span> (Director Q&amp;A)
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Sat 18:30 — <span class="text-zinc-200">Shorts Block: New Voices</span>
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Sun 20:15 — <span class="text-zinc-200">*The Lighthouse Revisited*</span> (Encore)
              </span>
              <span class="rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs md:text-sm">
                Mon 22:00 — <span class="text-zinc-200">*Cinema in Transit*</span>
              </span>
            </div> --%>
          </div>
        </div>
      </div>

      <%= cond do %>
        <% @showcase -> %>
          <.live_component
            id="theater-showcase"
            module={TheaterShowcaseComponent}
            showcase={@showcase}
            exhibitions={@exhibitions}
            presence={@presence}
            playback_states={@playback_states}
            timezone={@timezone}
          />
        <% @upcoming_showcase -> %>
          <section class="relative isolate">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10 md:py-12">
              <div class="overflow-hidden rounded-3xl border border-white/10 bg-white/2 shadow-[0_0_0_1px_rgba(255,255,255,0.03)]">
                <div class="grid grid-cols-1 md:grid-cols-5">
                  <!-- Image side -->
                  <div class="relative md:col-span-3 min-h-[260px] md:min-h-[340px]">
                    <img
                      src={~p"/images/upcoming_showcase.webp"}
                      alt="Upcoming showcase"
                      class="absolute inset-0 h-full w-full object-cover"
                    />
                    
    <!-- Overlays for readability -->
                    <div class="absolute inset-0 bg-linear-to-r from-backroom-black/90 via-backroom-black/55 to-transparent">
                    </div>
                    <div class="absolute inset-0 bg-linear-to-t from-backroom-black/70 via-transparent to-backroom-black/20">
                    </div>

                    <div class="relative p-6 md:p-8">
                      <div class="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/6 px-3 py-1">
                        <span class="h-2 w-2 rounded-full bg-neon-red-light animate-pulse"></span>
                        <span class="text-xs uppercase tracking-wider text-zinc-200">
                          Upcoming showcase
                        </span>
                      </div>

                      <h2 class="mt-4 text-3xl md:text-4xl font-semibold tracking-tight text-white">
                        {@upcoming_showcase.title}
                      </h2>

                      <p class="mt-3 max-w-xl text-sm md:text-base text-zinc-200/80">
                        {@upcoming_showcase.description}
                      </p>
                    </div>
                  </div>
                  
    <!-- Details side -->
                  <div class="md:col-span-2 p-6 md:p-8 bg-backroom-black/60">
                    <p class="text-xs uppercase tracking-wider text-zinc-400">Starts</p>

                    <p class="mt-2 text-lg md:text-xl font-medium text-white">
                      {format_datetime_in_timezone(@upcoming_showcase.start_at, @timezone)}
                      <span class="text-zinc-400 text-sm font-normal">
                        ({extract_city_from_timezone(@timezone)})
                      </span>
                    </p>

                    <p class="mt-3 text-sm text-zinc-400">
                      TimeSink opens its doors. No easing in. No settling down.
                    </p>

                    <div class="mt-6 flex flex-col sm:flex-row gap-3">
                      <button
                        type="button"
                        phx-click={show_modal("showcase-info-modal")}
                        class="inline-flex items-center justify-center rounded border border-white/15 bg-white/6 px-4.5 py-2 text-sm text-white transition hover:bg-white/10 hover:border-white/25 cursor-pointer"
                      >
                        Learn more
                      </button>

                      <button
                        type="button"
                        phx-click={show_modal("newsletter-modal")}
                        class="inline-flex items-center justify-center rounded bg-white text-backroom-black px-4.5 py-2 text-sm font-medium transition hover:opacity-90 cursor-pointer"
                      >
                        Get notified
                      </button>
                    </div>

                    <div class="mt-6 border-t border-white/10 pt-5">
                      <p class="text-xs uppercase tracking-wider text-zinc-400">What to expect</p>
                      <p class="mt-2 text-sm text-zinc-400">
                        A curated drop. Live chat in every room. A night where everything begins.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>
        <% @no_showcase -> %>
          <.no_showcase />
      <% end %>
      <.live_component
        module={ScheduleModalComponent}
        id="schedule-modal-component"
        showcase={@showcase}
        upcoming_showcase={@upcoming_showcase}
        exhibitions={@exhibitions}
        playback_states={@playback_states}
        presence={@presence}
        timezone={@timezone}
      />

      <.live_component
        module={TimesinkWeb.ShowcaseInfoModalComponent}
        id="showcase-info-modal-component"
      />

      <.live_component module={TimesinkWeb.NewsletterModalComponent} id="newsletter-modal-component" />
      <.live_component module={TimesinkWeb.LineupInfoModalComponent} id="lineup-info-modal-component" />
      <.live_component module={TimesinkWeb.LiveInfoModalComponent} id="live-info-modal-component" />
      <.live_component
        module={TimesinkWeb.CommunityInfoModalComponent}
        id="community-info-modal-component"
      />
    </div>
    """
  end

  def handle_info(:connected, socket) do
    presence =
      socket.assigns.exhibitions
      |> Enum.map(fn ex ->
        presence_topic = PubSubTopics.presence_topic(ex.theater_id)
        playback_phase_change_topic = PubSubTopics.phase_change_topic(ex.theater_id)
        Phoenix.PubSub.subscribe(Timesink.PubSub, presence_topic)

        Phoenix.PubSub.subscribe(Timesink.PubSub, playback_phase_change_topic)

        {presence_topic, Presence.list(presence_topic)}
      end)
      |> Enum.into(%{})

    {:noreply, assign(socket, :presence, presence)}
  end

  def handle_info(
        %{
          event: "phase_change",
          playback_state:
            %{
              theater_id: theater_id
            } = playback_state
        },
        socket
      ) do
    updated_states =
      Map.update(socket.assigns[:playback_states] || %{}, theater_id, playback_state, fn _ ->
        playback_state
      end)

    {:noreply, assign(socket, :playback_states, updated_states)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    {:noreply, update(socket, :presence, &Map.put(&1, topic, updated))}
  end

  # ───────────────────────────────────────────────────────────
  # Timezone Helpers
  # ───────────────────────────────────────────────────────────

  defp format_datetime_in_timezone(nil, _timezone), do: "TBA"

  defp format_datetime_in_timezone(naive_dt, timezone) do
    naive_dt
    |> DateTime.from_naive!("Etc/UTC")
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%A, %B %d · %H:%M", :strftime)
  end

  defp extract_city_from_timezone("Etc/UTC"), do: "UTC"

  defp extract_city_from_timezone(timezone) do
    # Extract city from IANA timezone like "America/New_York" -> "New York"
    timezone
    |> String.split("/")
    |> List.last()
    |> String.replace("_", " ")
  end
end
