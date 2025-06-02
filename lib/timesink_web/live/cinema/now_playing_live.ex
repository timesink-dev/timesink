defmodule TimesinkWeb.Cinema.NowPlayingLive do
  use TimesinkWeb, :live_view
  alias Timesink.Repo

  import Ecto.Query
  import TimesinkWeb.Components.{TheaterCard, TheaterCardMobile}

  alias Timesink.Cinema.Showcase
  alias TimesinkWeb.Presence

  def mount(_params, _session, socket) do
    showcase =
      Showcase
      |> where([s], s.status == :active)
      |> preload([:exhibitions])
      |> Repo.one()

    exhibitions =
      (showcase && showcase.exhibitions) || []

    exhibitions =
      Repo.preload(exhibitions, [
        :theater,
        film: [
          :genres,
          video: [:blob],
          poster: [:blob],
          trailer: [:blob],
          directors: [:creative],
          cast: [:creative],
          writers: [:creative],
          producers: [:creative],
          crew: [:creative]
        ]
      ])
      |> Enum.sort_by(& &1.theater.name, :asc)

    default_index = 0
    default_exhibition = Enum.at(exhibitions, default_index)

    selected_theater_id =
      default_exhibition && default_exhibition.theater && default_exhibition.theater.id

    socket =
      socket
      |> assign(:showcase, showcase)
      |> assign(:exhibitions, exhibitions)
      |> assign(:selected_theater_id, selected_theater_id)
      |> assign(:selected_index, default_index)
      |> assign(:presence, %{})

    if connected?(socket), do: send(self(), :connected)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="now-playing">
      <div class="bg-backroom-black py-16 px-6 max-w-7xl mx-auto">
        <div class="hidden lg:flex flex-row gap-24">
          <div class="flex flex-col space-y-12 w-1/5">
            <%= for exhibition <- @exhibitions do %>
              <div
                phx-click="select_theater"
                phx-value-id={exhibition.theater.id}
                class={[
                  "bg-dark-theater-primary rounded-lg p-4 shadow-md cursor-pointer transition",
                  "hover:bg-dark-theater-light",
                  @selected_theater_id == exhibition.theater.id && "ring-1 ring-neon-blue-lightest"
                ]}
              >
                <div class="flex justify-between items-start mb-2">
                  <h3 class="text-white font-semibold text-lg">
                    {exhibition.theater.name}
                  </h3>
                  <div class="text-xs text-white/60">
                    <.icon name="hero-user-group" class="h-5 w-5" />
                    {live_viewer_count("theater:#{exhibition.theater_id}", @presence)}
                  </div>
                </div>
                <div class="mt-6 text-neon-blue-lightest text-sm font-medium">
                  {exhibition.film.title}
                </div>
              </div>
            <% end %>
          </div>

          <div class="flex-1">
            <%= for exhibition <- @exhibitions do %>
              <%= if @selected_theater_id == exhibition.theater.id do %>
                <.theater_card
                  exhibition={exhibition}
                  live_viewer_count={
                    live_viewer_count(
                      "theater:#{exhibition.theater_id}",
                      @presence
                    )
                  }
                />
              <% else %>
                {nil}
              <% end %>
            <% end %>
          </div>
        </div>

        <div class="block lg:hidden px-4 space-y-6 max-w-screen-lg mx-auto">
          <div id="embla-main" phx-hook="EmblaMain" class="overflow-hidden">
            <div class="flex gap-4 px-4">
              <%= for {exhibition, _index} <- Enum.with_index(@exhibitions) do %>
                <.theater_card_mobile
                  exhibition={exhibition}
                  live_viewer_count={
                    live_viewer_count(
                      "theater:#{exhibition.theater_id}",
                      @presence
                    )
                  }
                />
              <% end %>
            </div>
          </div>
          <div class="px-2 pt-6">
            <h2 class="text-mystery-white text-md uppercase">
              View all theaters →
            </h2>
          </div>
          <div id="embla-thumbs" phx-hook="EmblaThumbs" class="overflow-hidden w-full p-2">
            <div class="flex gap-2">
              <%= for {exhibition, index} <- Enum.with_index(@exhibitions) do %>
                <img
                  src={Timesink.Cinema.Film.poster_url(exhibition.film.poster)}
                  alt={exhibition.film.title}
                  data-thumb-index={index}
                  class="object-cover rounded-md w-28 h-28 transition-all duration-300 cursor-pointer"
                />
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_theater", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_theater_id: id)}
  end

  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    updated = Presence.list(topic)
    new_presence = Map.put(socket.assigns.presence, topic, updated)
    {:noreply, assign(socket, :presence, new_presence)}
  end

  def handle_info(:connected, socket) do
    exhibitions = socket.assigns.exhibitions

    Enum.each(exhibitions, fn ex ->
      topic = "theater:#{ex.theater_id}"
      Phoenix.PubSub.subscribe(Timesink.PubSub, topic)
    end)

    updated_presence =
      Enum.reduce(exhibitions, %{}, fn ex, acc ->
        topic = "theater:#{ex.theater_id}"
        Map.put(acc, topic, Presence.list(topic))
      end)

    {:noreply, assign(socket, :presence, updated_presence)}
  end

  defp live_viewer_count(theater_id, presence) do
    # determine the joining (before it was "theater:#{theater_id}"), but that was producing
    # a dpulicate "theater:theater:#{theater_id}" topic
    topic = "#{theater_id}"
    Map.get(presence, topic, %{}) |> map_size()
  end
end
