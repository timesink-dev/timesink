defmodule TimesinkWeb.TheaterShowcaseComponent do
  use TimesinkWeb, :live_component

  import TimesinkWeb.Components.{TheaterCard, TheaterCardMobile}
  alias TimesinkWeb.PubSubTopics

  def update(assigns, socket) do
    old_selected_id = socket.assigns[:selected_theater_id]

    default_theater_id =
      assigns.exhibitions
      |> List.first()
      |> then(& &1.theater.id)

    selected_theater_id = old_selected_id || default_theater_id

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_theater_id, selected_theater_id)}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-backroom-black py-16 px-6 max-w-7xl mx-auto mt-12">
      <div class="mb-32 md:mb-72 max-w-3xl mx-auto text-center px-4">
        <h2 class="text-xl tracking-tight text-mystery-white font-gangter uppercase">
          Featured Showcase
        </h2>
        <div class="h-1 w-20 my-8 bg-neon-blue-lightest mx-auto animate-pulse rounded-full" />
        <div class="text-xl font-light text-neon-blue-lightest mb-2">
          {@showcase.title}
        </div>
        <div class="text-gray-400 text-sm leading-relaxed max-w-lg mx-auto font-light text-center">
          {@showcase.description}
        </div>
      </div>

      <div class="hidden lg:flex flex-row gap-24">
        <div class="flex flex-col space-y-12 w-1/5">
          <%= for exhibition <- @exhibitions do %>
            <button
              phx-click="select_theater"
              phx-value-id={exhibition.theater.id}
              phx-target={@myself}
              class={[
                "bg-dark-theater-primary rounded-lg p-4 shadow-md cursor-pointer transition text-left",
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
                  {live_viewer_count(exhibition.theater_id, @presence)}
                </div>
              </div>
              <div class="mt-6 text-mystery-white font-semibold text-lg">
                {exhibition.film.title}
              </div>
            </button>
          <% end %>
        </div>
        <div class="flex-1">
          <%= for exhibition <- @exhibitions do %>
            <%= if @selected_theater_id == exhibition.theater.id do %>
              <.theater_card
                exhibition={exhibition}
                playback_state={Map.get(@playback_states, to_string(exhibition.theater_id))}
                live_viewer_count={
                  live_viewer_count(
                    exhibition.theater_id,
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
                playback_state={Map.get(@playback_states, to_string(exhibition.theater_id))}
                live_viewer_count={
                  live_viewer_count(
                    exhibition.theater_id,
                    @presence
                  )
                }
              />
            <% end %>
          </div>
        </div>
        <div class="px-2 pt-6">
          <h2 class="text-mystery-white text-md  font-brand">
            View All Theaters →
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
    topic = PubSubTopics.presence_topic(theater_id)
    Map.get(presence, topic, %{}) |> map_size()
  end
end
