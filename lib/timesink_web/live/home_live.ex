defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Presence
  alias Timesink.Cinema
  alias TimesinkWeb.{TheaterShowcaseComponent, PubSubTopics}
  import TimesinkWeb.Components.Hero

  def mount(_params, _session, socket) do
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
          no_showcase: false
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
               no_showcase: false
             )}

          nil ->
            {:ok,
             assign(socket,
               showcase: nil,
               exhibitions: [],
               playback_states: %{},
               presence: %{},
               upcoming_showcase: nil,
               no_showcase: true
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

      <div id="cinema-barrier" class="h-16" phx-hook="ScrollObserver" />

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
            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
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
              <h3 class="text-lg font-medium">Hand-picked lineup</h3>
              <p class="mt-1 text-sm text-zinc-400">
                Spotlight on retrospectives, festival favorites, hidden gems, and filmmaker premieres.
              </p>
            </div>

            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
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
              <h3 class="text-lg font-medium">
                Live for every showing
              </h3>
              <p class="mt-1 text-sm text-zinc-400">
                Live chats to engage with real people, not noisy comment walls.
              </p>
            </div>

            <div class="group rounded-2xl border border-white/10 bg-white/[0.02] p-5 transition hover:border-white/20 hover:bg-white/[0.04]">
              <div class="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
                <!-- globe icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm6.93 6h-3.26a14.6 14.6 0 0 0-2.01-4.2A8.03 8.03 0 0 1 18.93 8ZM12 4.06c.9 1.17 1.67 2.67 2.2 3.94H9.8c.53-1.27 1.3-2.77 2.2-3.94ZM5.07 8h3.26c.34-1.02.8-2.07 1.34-3.02A8.03 8.03 0 0 0 5.07 8Zm0 8a8.03 8.03 0 0 1 4.6 3.02A14.6 14.6 0 0 1 8.33 16H5.07Zm4.73 0h4.4c-.53 1.27-1.3 2.77-2.2 3.94-.9-1.17-1.67-2.67-2.2-3.94Zm8.13 0h-3.26c-.34 1.02-.8 2.07-1.34 3.02A8.03 8.03 0 0 0 17.93 16Zm-1.6-6c.27.96.45 2 .5 3.05H7.17c.05-1.05.23-2.09.5-3.05h8.66Z" />
                </svg>
              </div>
              <h3 class="text-lg font-medium">Global community</h3>
              <p class="mt-1 text-sm text-zinc-400">
                Join a network of viewers from everywhere. Discover, discuss, connect, repeat.
              </p>
            </div>
          </div>
          
    <!-- slim schedule teaser -->
          <div class="mt-10 rounded-2xl border border-white/10 bg-gradient-to-r from-white/[0.03] to-white/[0.01] p-5">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <p class="text-sm uppercase tracking-wider text-zinc-400">This Week</p>
                <h4 class="mt-1 text-lg font-medium">Upcoming screenings &amp; special events</h4>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <div class="inline-flex items-center gap-2 rounded-full bg-white/[0.06] px-3 py-1">
                  <div class="h-2 w-2 rounded-full animate-pulse bg-current text-neon-red-light">
                  </div>
                  Live showings every 30 minutes
                </div>
                <button class="rounded-full border border-white/15 px-3 py-1 hover:bg-white/[0.06] hover:cursor-not-allowed">
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
          />
        <% @upcoming_showcase -> %>
          <div class="text-center text-white my-32 px-6 max-w-xl mx-auto h-[100vh] flex flex-col items-center justify-center">
            <.icon name="hero-clock" class="h-16 w-16 mb-6 text-neon-blue-lightest" />
            <h1 class="text-4xl font-bold mb-4">Upcoming Showcase</h1>
            <h2 class="text-2xl font-semibold text-neon-blue-lightest mb-2">
              {@upcoming_showcase.title}
            </h2>
            <p class="text-gray-400 mb-4">
              {@upcoming_showcase.description}
            </p>
            <p class="text-gray-500 text-sm">
              Starts
              <span class="font-medium">
                {Calendar.strftime(@upcoming_showcase.start_at, "%A, %B %d at %H:%M")}
              </span>
            </p>
          </div>
        <% @no_showcase -> %>
          <section class="text-white my-8 px-6 max-w-3xl mx-auto min-h-[80vh] flex items-center">
            <div class="w-full text-center">
              <div class="mx-auto mb-3 h-9 w-9 rounded-full bg-zinc-900 ring-1 ring-zinc-800
                      flex items-center justify-center text-zinc-300">
                📌
              </div>

              <h1 class="text-4xl font-bold tracking-tight mb-3">
                We’re working on our first showcase...
              </h1>
              <p class="text-zinc-400 text-balance max-w-2xl mx-auto">
                TimeSink is a live, curated cinema. When there isn’t an active release, we’re busy selecting the next one. Keep checking back soon.
              </p>
              
    <!-- Feature highlights -->
              <div class="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left">
                  <div class="mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
                    <.icon name="hero-video-camera" class="h-4 w-4 text-neon-blue-lightest" />
                  </div>
                  <div class="text-sm text-zinc-300">
                    Both rookie and veteran filmmakers welcome
                  </div>
                </div>
                <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left">
                  <div class="mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
                    <.icon name="hero-chat-bubble-left-right" class="h-4 w-4 text-neon-blue-lightest" />
                  </div>
                  <div class="text-sm text-zinc-300">
                    Live screenings with real-time audiences
                  </div>
                </div>
                <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left">
                  <div class="mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
                    <.icon name="hero-play" class="h-4 w-4 text-neon-blue-lightest" />
                  </div>
                  <div class="text-sm text-zinc-300">Live showtimes every 30 minutes</div>
                </div>
                <div class="rounded-2xl border border-white/10 bg-white/[0.02] p-4 text-left">
                  <div class="mb-3 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-white/[0.06]">
                    <.icon name="hero-sparkles" class="h-4 w-4 text-neon-blue-lightest" />
                  </div>
                  <div class="text-sm text-zinc-300">Retrospectives, premieres, hidden gems</div>
                </div>
              </div>
              
    <!-- CTAs -->
              <div class="mt-8 flex items-center justify-center gap-3">
                <.link
                  navigate="/submit"
                  class="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/[0.06] px-4 py-2 text-sm text-white hover:bg-white/[0.10] transition"
                >
                  <.icon name="hero-arrow-up-tray" class="h-4 w-4" /> Submit your film
                </.link>
                <.link
                  navigate="/info"
                  class="inline-flex items-center gap-2 rounded-xl border border-white/10 px-4 py-2 text-sm text-zinc-300 hover:bg-white/[0.06] transition"
                >
                  <.icon name="hero-information-circle" class="h-4 w-4" /> How programming works
                </.link>
              </div>
              <p class="mt-6 text-sm text-zinc-500">
                Have any questions? contact
                hello@timesinkpresents.com
              </p>
            </div>
          </section>
      <% end %>
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
end
