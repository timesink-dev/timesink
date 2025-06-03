defmodule TimesinkWeb.TheaterShowcaseComponent do
  use TimesinkWeb, :live_component
  alias Timesink.Cinema

  import TimesinkWeb.Components.{TheaterCard, TheaterCardMobile}

  def update(%{showcase: showcase, presence: presence} = assigns, socket) do
    exhibitions =
      (showcase && showcase.exhibitions) || []

    exhibitions =
      exhibitions |> Cinema.preload_exhibitions() |> Enum.sort_by(& &1.theater.name, :asc)

    default_exhibition = Enum.at(exhibitions, 0)
    selected_theater_id = default_exhibition && default_exhibition.theater.id

    socket =
      socket
      |> assign(assigns)
      |> assign(:showcase, showcase)
      |> assign(:exhibitions, exhibitions)
      |> assign(:selected_theater_id, selected_theater_id)
      |> assign(:presence, presence || %{})

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-backroom-black py-16 px-6 max-w-7xl mx-auto mt-12">
      <div class="mb-24 max-w-3xl mx-auto text-center px-4">
        <h2 class="text-4xl md:text-5xl tracking-tight text-white mb-4 uppercase">
          Featured ShowCase
        </h2>
        <div class="h-1 w-20 bg-neon-blue-lightest mx-auto mb-6 animate-pulse rounded-full" />
        <div class="text-xl md:text-2xl font-semibold text-neon-blue-lightest mb-2">
          {@showcase.title}
        </div>
        <div class="text-mystery-white text-base md:text-lg font-light leading-relaxed max-w-2xl mx-auto">
          {@showcase.description}
        </div>
      </div>

      <div class="hidden lg:flex flex-row gap-24">
        <div class="flex flex-col space-y-12 w-1/5">
          <%= for exhibition <- @exhibitions do %>
            <div
              phx-click="select_theater"
              phx-value-id={exhibition.theater.id}
              phx-target={@myself}
              class={[
                "bg-dark-theater-primary rounded-lg p-4 shadow-md cursor-pointer transition",
                "hover:bg-dark-theater-light",
                @selected_theater_id == exhibition.theater.id && "ring-1 ring-neon-blue-lightest"
              ]}
            >
              <div class="flex justify-between items-start mb-2">
                <h3 class="text-white text-sm font-medium">
                  {exhibition.theater.name}
                </h3>
                <div class="text-xs text-white/60">
                  <.icon name="hero-user-group" class="h-5 w-5" />
                  {live_viewer_count("theater:#{exhibition.theater_id}", @presence)}
                </div>
              </div>
              <div class="mt-6 text-mystery-white font-semibold text-lg">
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
          <div class="flex gap-4">
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
    """
  end

  def handle_event("select_theater", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_theater_id: id)}
  end

  defp live_viewer_count(theater_id, presence) do
    # determine the joining (before it was "theater:#{theater_id}"), but that was producing
    # a duplicate "theater:theater:#{theater_id}" topic
    topic = "#{theater_id}"
    Map.get(presence, topic, %{}) |> map_size()
  end
end
