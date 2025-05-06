defmodule TimesinkWeb.Admin.ExhibitionsLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    showcases = Timesink.Repo.all(Timesink.Cinema.list_ordered_showcases())

    theaters = Timesink.Repo.all(Timesink.Cinema.Theater)
    films = Timesink.Cinema.Film.all()

    {:ok, assign(socket, showcases: showcases, films: films, theaters: theaters),
     layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-backroom-black text-white px-4 md:px-8 py-10">
      <div class="flex flex-col md:flex-row gap-8">
        <!-- Sidebar with Films -->
        <div class="md:w-1/4">
          <h2 class="text-xl font-bold mb-4 text-neon-blue">🎬 Films</h2>
          <div class="space-y-2">
            <%= for film <- @films do %>
              <div
                id={"film-#{film.id}"}
                class="bg-dark-theater-medium hover:bg-dark-theater-lightest transition rounded-lg px-3 py-2 cursor-move text-mystery-white text-sm"
                draggable="true"
                phx-hook="Draggable"
                data-film-id={film.id}
              >
                {film.title}
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Showcase Cards -->
        <div class="flex-1 space-y-10">
          <h2 class="text-2xl font-bold text-white mb-6">📅 Showcases</h2>

          <%= for showcase <- @showcases do %>
            <div class={[
              "rounded-2xl overflow-hidden shadow-lg transform transition-all duration-300 ease-in-out",
              showcase.status == :active &&
                "bg-green-900/40 border border-green-500 hover:border-green-300 hover:shadow-xl hover:scale-[1.01]",
              showcase.status != :active &&
                "bg-obsidian/70 border border-dark-theater-light hover:border-neon-blue-lightest hover:shadow-md hover:scale-[1.01]"
            ]}>
              <div class="p-6">
                <div class="flex items-center justify-between mb-4 flex-wrap gap-2">
                  <h3 class={[
                    "text-xl font-semibold flex items-center gap-2",
                    showcase.status == :active && "text-green-300"
                  ]}>
                    <%= if showcase.status == :active do %>
                      🟢
                    <% end %>
                    {showcase.title}
                  </h3>

                  <div class="text-xs text-gray-400 mb-4 flex flex-start gap-x-4">
                    <p class="text-xs text-gray-400 mb-1">
                      🕒 <strong>Showtime:</strong>
                      {(showcase.start_at && Calendar.strftime(showcase.start_at, "%m/%d/%Y %I:%M %p")) ||
                        "Not set"}
                    </p>
                    <p class="text-xs text-gray-400 mb-4">
                      <strong>Ends:</strong>
                      {(showcase.end_at && Calendar.strftime(showcase.end_at, "%m/%d/%Y %I:%M %p")) ||
                        "Not set"}
                    </p>
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                  <%= for theater <- @theaters do %>
                    <div
                      id={"theater-#{theater.id}-showcase-#{showcase.id}"}
                      class="bg-backroom-black/60 border border-dark-theater-medium rounded-xl p-4 min-h-[100px] transition duration-300 ease-in-out hover:border-neon-blue hover:shadow-md"
                      phx-hook="DropZone"
                      data-showcase-id={showcase.id}
                      data-theater-id={theater.id}
                    >
                      <p class="text-sm font-medium text-white mb-2">{theater.name}</p>
                      <%= for exhibition <- showcase.exhibitions,
    exhibition.theater_id == theater.id do %>
                        <div class="flex items-center gap-2 bg-dark-theater-medium bg-opacity-60 text-white text-sm px-3 py-2 rounded-lg mt-2 max-w-full break-words shadow-sm">
                          <span class="text-red-500 text-xs">🔴</span>
                          <span class="truncate flex-1">{exhibition.film.title}</span>
                        </div>
                      <% end %>

                      <%= if Enum.empty?(Enum.filter(showcase.exhibitions, &(&1.theater_id == theater.id))) do %>
                        <p class="text-gray-500 italic text-xs">Drop films here</p>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event(
        "create_exhibition",
        %{"film_id" => film_id, "showcase_id" => showcase_id, "theater_id" => theater_id},
        socket
      ) do
    case Timesink.Cinema.create_exhibition(%{
           film_id: film_id,
           showcase_id: showcase_id,
           theater_id: theater_id
         }) do
      {:ok, _exhibition} ->
        showcases = Timesink.Repo.all(Timesink.Cinema.list_ordered_showcases())

        {:noreply,
         socket
         |> assign(:showcases, showcases)
         |> put_flash(:info, "Exhibition added.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add exhibition.")}
    end
  end
end
