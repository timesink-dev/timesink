defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.{Theater, Exhibition, Showcase, Film}
  alias TimesinkWeb.PubSubTopics
  alias Timesink.Repo
  require Logger

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Theater.get_by(%{slug: theater_slug}),
         {:ok, showcase} <- Showcase.get_by(%{status: :active}),
         {:ok, exhibition} <-
           Exhibition.get_by(%{theater_id: theater.id, showcase_id: showcase.id}),
         {:ok, film} <- Film.get(exhibition.film_id) do
      exhibition = Repo.preload(exhibition, [:showcase, :theater])

      film =
        Repo.preload(film, [
          {:video, [:blob]},
          {:poster, [:blob]},
          :genres,
          directors: [:creative],
          cast: [:creative],
          writers: [:creative],
          producers: [:creative],
          crew: [:creative]
        ])

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Timesink.PubSub, PubSubTopics.scheduler_topic(theater.id))
        Phoenix.PubSub.subscribe(Timesink.PubSub, PubSubTopics.presence_topic(theater.id))

        TimesinkWeb.Presence.track(
          self(),
          PubSubTopics.presence_topic(theater.id),
          "#{socket.assigns.current_user.id}",
          %{
            username: socket.assigns.current_user.username,
            joined_at: System.system_time(:second)
          }
        )
      end

      presence_topic = PubSubTopics.presence_topic(theater.id)
      presence = TimesinkWeb.Presence.list(presence_topic)

      {:ok,
       socket
       |> assign(:theater, theater)
       |> assign(:exhibition, exhibition)
       |> assign(:film, film)
       |> assign(:user, socket.assigns.current_user)
       |> assign(:presence, presence)
       |> assign(:offset, nil)
       |> assign(:phase, nil)
       |> assign(:countdown, nil)
       |> assign(:pulse_seconds_only?, false)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div
      id="theater"
      class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100 mt-16 flex justify-between gap-x-12"
    >
      <div class="flex-1">
        <div class="border-b border-gray-700 pb-4 mb-10">
          <h1 class="text-xl font-bold">{@theater.name}</h1>
          <p class="text-gray-400 mt-2 text-sm">{@theater.description}</p>
        </div>

        <div>
          <% playback_id = Film.get_mux_playback_id(@film.video) %>
          <%= if @phase == :playing and playback_id do %>
            <div id="simulated-live-player" data-offset={@offset} phx-hook="SimulatedLivePlayback">
              <mux-player
                id={@film.title}
                playback-id={playback_id}
                metadata-video-title={@film.title}
                metadata-video-id={@film.id}
                metadata-viewer_user_id={@user.id}
                poster={Film.poster_url(@film.poster)}
                style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 8px; overflow: hidden; border-color: #1f2937; border-width: 1px;"
                stream-type="live"
                autoplay
                loop
                start-time={@offset}
              />
            </div>
          <% else %>
            <div class="text-center text-gray-400 text-xl py-8">
              <%= if is_nil(@countdown) do %>
                <div class="flex flex-col items-center justify-center gap-2 text-gray-400">
                  <h3 class="font-semibold">Loading schedule...</h3>
                  <div class="h-4 w-4 border-2 border-t-transparent border-gray-400 rounded-full animate-spin" />
                </div>
              <% else %>
                <div class="flex flex-col justify-center text-center gap-y-2">
                  <h3 class="text-gray-400">
                    <%= case @phase do %>
                      <% :upcoming -> %>
                        This showcase is scheduled and will begin shortly.
                      <% :intermission -> %>
                        Intermission — next screening begins in
                      <% _ -> %>
                        Waiting for playback...
                    <% end %>
                  </h3>
                  <div class="flex justify-center gap-x-4 mt-2 text-center">
                    <%= for {label, value} <- breakdown_time(@countdown) do %>
                      <div class="flex flex-col items-center mx-2">
                        <span class={
        "text-3xl font-bold" <>
          if label == :seconds and @pulse_seconds_only?, do: " pulse-second text-neon-blue-light", else: ""
      }>
                          {String.pad_leading(to_string(value), 2, "0")}
                        </span>
                        <span class="text-xs uppercase text-gray-400 tracking-wider">
                          {Atom.to_string(label)}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_info(
        %{
          event: "tick",
          playback_state: %{
            phase: phase,
            offset: offset,
            countdown: countdown,
            theater_id: _theater_id
          }
        },
        socket
      ) do
    # consider in future - to sync more aggresively on playback start time if lagging
    # if phase == :playing and offset do
    #   push_event(socket, "sync_offset", %{offset: offset})
    # end

    time_parts = breakdown_time(countdown || 0)
    pulse_seconds_only? = Enum.all?(time_parts, fn {unit, _} -> unit == :seconds end)

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:countdown, countdown)
     |> assign(:pulse_seconds_only?, pulse_seconds_only?)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    presence = TimesinkWeb.Presence.list(topic)
    {:noreply, assign(socket, presence: presence)}
  end

  def handle_info(
        %{
          event: "phase_change",
          playback_state: %{
            phase: phase,
            offset: offset,
            countdown: countdown
          }
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:offset, offset)
     |> assign(:countdown, countdown)}
  end

  defp breakdown_time(nil), do: []

  defp breakdown_time(seconds) when is_float(seconds),
    do: breakdown_time(trunc(seconds))

  defp breakdown_time(total) when is_integer(total) do
    days = div(total, 86_400)
    hours = rem(total, 86_400) |> div(3_600)
    minutes = rem(total, 3_600) |> div(60)
    seconds = rem(total, 60)

    Enum.filter(
      [
        {:days, days},
        {:hours, hours},
        {:minutes, minutes},
        {:seconds, seconds}
      ],
      fn {_k, v} -> v > 0 end
    )
  end
end
