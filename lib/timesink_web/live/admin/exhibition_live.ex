defmodule TimesinkWeb.Admin.ExhibitionsLive do
  alias Timesink.Cinema.Exhibition
  use TimesinkWeb, :live_view

  import Ecto.Query

  def mount(_params, _session, socket) do
    showcases = refresh_showcases()

    theaters =
      Timesink.Repo.all(
        from t in Timesink.Cinema.Theater,
          order_by: [asc: t.name]
      )

    films = Timesink.Cinema.Film.all()

    {:ok,
     assign(socket,
       showcases_active_and_upcoming: Enum.reject(showcases, &(&1.status == :archived)),
       showcases_archived: Enum.filter(showcases, &(&1.status == :archived)),
       films: films,
       theaters: theaters
     ), layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-backroom-black text-mystery-white px-6 py-10 max-w-screen-2xl mx-auto">
      <div class="flex flex-col md:flex-row gap-8">
        <div class="md:w-1/4 space-y-6">
          <.button color="none" class="p-0 text-left" phx-click="go_back">
            ← Admin console
          </.button>

          <div>
            <h2 class="text-xl font-bold mb-4">🎥 Films</h2>
            <div class="space-y-2">
              <%= for film <- @films do %>
                <div
                  id={"film-#{film.id}"}
                  class="bg-dark-theater-primary hover:bg-dark-theater-lightest transition rounded-lg px-3 py-2 cursor-move text-mystery-white text-sm"
                  draggable="true"
                  phx-hook="ExhibitionDraggable"
                  data-film-id={film.id}
                >
                  {film.title}
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="flex-1 space-y-10">
          <h2 class="text-2xl font-bold text-white mb-6">📅 Showcases</h2>

          <%= for showcase <- @showcases_active_and_upcoming do %>
            <div class={[
              "rounded-2xl overflow-hidden shadow-lg transform transition-all duration-300 ease-in-out w-full",
              showcase.status == :active &&
                "bg-green-900/40 border border-green-500 hover:border-green-300 hover:shadow-xl hover:scale-[1.01]",
              showcase.status != :active &&
                "bg-obsidian/70 border border-dark-theater-light hover:border-neon-blue-lightest hover:shadow-md hover:scale-[1.01]"
            ]}>
              <div class="p-8 md:p-10">
                <div class="flex flex-col items-start justify-between mb-2 flex-wrap gap-x-2">
                  <div class="flex flex-wrap items-center justify-between">
                    <div>
                      <h3 class={[
                        "text-xl font-semibold flex items-center gap-2 mb-2.5",
                        showcase.status == :active && "text-green-300"
                      ]}>
                        <%= if showcase.status == :active do %>
                          🟢
                        <% end %>
                        {showcase.title}
                      </h3>

                      <div class="text-xs text-gray-400 flex justify-start gap-x-4 w-full">
                        <p>
                          🕒 <strong>Showtime:</strong>
                          <%= if showcase.start_at do %>
                            {Calendar.strftime(showcase.start_at, "%B %-d, %Y: %I:%M%p")} (UTC)
                          <% else %>
                            Not set
                          <% end %>
                        </p>
                        <p>
                          <strong>Ends:</strong>
                          <%= if showcase.end_at do %>
                            {Calendar.strftime(showcase.end_at, "%B %-d, %Y: %I:%M%p")} (UTC)
                          <% else %>
                            Not set
                          <% end %>
                        </p>
                      </div>
                    </div>
                  </div>
                  <p class="text-sm text-gray-400 mb-4 mt-2.5">
                    <%= if showcase.description && String.trim(showcase.description) != "" do %>
                      {showcase.description}
                    <% else %>
                      <em>No description yet...</em>
                    <% end %>
                  </p>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-2 gap-4">
                  <%= for theater <- @theaters do %>
                    <div
                      id={"theater-#{theater.id}-showcase-#{showcase.id}"}
                      class="bg-backroom-black/60 border border-dark-theater-medium rounded-xl p-4 min-h-[100px] transition duration-300 ease-in-out hover:border-neon-blue-lightest hover:shadow-md"
                      phx-hook="ExhibitionDropZone"
                      data-showcase-id={showcase.id}
                      data-theater-id={theater.id}
                    >
                      <p class="text-sm font-medium text-white mb-2">{theater.name}</p>
                      <%= for exhibition <- showcase.exhibitions,
      exhibition.theater_id == theater.id do %>
                        <div class="relative group bg-dark-theater-medium bg-opacity-60 text-white text-sm px-3 py-2 rounded-lg mt-2 shadow-sm w-full">
                          <button
                            type="button"
                            phx-click="remove_exhibition"
                            phx-value-id={exhibition.id}
                            class="absolute -top-2 -right-2 transform text-gray-400 text-xs font-bold transition-opacity opacity-0 group-hover:opacity-100 z-10"
                            title="Remove"
                          >
                            <.icon
                              name="hero-x-circle-solid"
                              class="h-5 w-5 opacity-100 group-hover:opacity-70"
                            />
                          </button>

                          <div class="flex justify-between items-center gap-2 pr-6">
                            <span>🔴</span>
                            <span class="text-sm">{exhibition.film.title}</span>
                          </div>
                        </div>
                      <% end %>

                      <%= if Enum.empty?(Enum.filter(showcase.exhibitions, &(&1.theater_id == theater.id))) do %>
                        <p class="text-gray-500 italic text-xs">Drop film here...</p>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
          <%= if @showcases_archived != [] do %>
            <div class="border-t border-gray-600 mt-16 pt-10">
              <h2 class="text-xl font-bold text-gray-400 mb-6">📦 Archived Showcases</h2>

              <div class="space-y-10">
                <%= for showcase <- @showcases_archived do %>
                  <div class="bg-obsidian/60 border border-gray-700 rounded-2xl overflow-hidden shadow-md w-full">
                    <div class="p-8 md:p-10">
                      <h3 class="text-xl font-semibold text-white flex items-center gap-2 mb-2.5">
                        🗃️ {showcase.title}
                      </h3>

                      <div class="text-xs text-gray-400 flex justify-start gap-x-4 w-full mb-3">
                        <p>
                          🕒 <strong>Showtime:</strong>
                          <%= if showcase.start_at do %>
                            {Calendar.strftime(showcase.start_at, "%B %-d, %Y: %I:%M%p")} (UTC)
                          <% else %>
                            Not set
                          <% end %>
                        </p>
                        <p>
                          <strong>Ends:</strong>
                          <%= if showcase.end_at do %>
                            {Calendar.strftime(showcase.end_at, "%B %-d, %Y: %I:%M%p")} (UTC)
                          <% else %>
                            Not set
                          <% end %>
                        </p>
                      </div>

                      <p class="text-sm text-gray-400 mb-6">
                        <%= if showcase.description && String.trim(showcase.description) != "" do %>
                          {showcase.description}
                        <% else %>
                          <em>No description yet...</em>
                        <% end %>
                      </p>

                      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-2 gap-4">
                        <%= for theater <- @theaters do %>
                          <div class="bg-backroom-black/50 border border-dark-theater-medium rounded-xl p-4 min-h-[80px]">
                            <p class="text-sm font-medium text-white mb-2">{theater.name}</p>

                            <%= for exhibition <- showcase.exhibitions,
                    exhibition.theater_id == theater.id do %>
                              <div class="bg-dark-theater-medium/70 text-white text-sm px-3 py-2 rounded-lg mt-2 shadow-sm w-full">
                                <div class="flex justify-between items-center gap-2">
                                  <span>🎞️</span>
                                  <span class="text-sm">{exhibition.film.title}</span>
                                </div>
                              </div>
                            <% end %>

                            <%= if Enum.empty?(Enum.filter(showcase.exhibitions, &(&1.theater_id == theater.id))) do %>
                              <p class="text-gray-500 italic text-xs">
                                No film scheduled in this theater
                              </p>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>
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
    with {:ok, _exhibition} <-
           Exhibition.upsert(%{
             "film_id" => film_id,
             "showcase_id" => showcase_id,
             "theater_id" => theater_id
           }) do
      {:noreply,
       socket
       |> assign(:showcases_active_and_upcoming, refresh_showcases())
       |> put_flash(:success, "Exhibition scheduled.")}
    else
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to schedule exhibiton.")}
    end
  end

  def handle_event("remove_exhibition", %{"id" => id}, socket) do
    with %Timesink.Cinema.Exhibition{} = exhibition <-
           Timesink.Repo.get(Timesink.Cinema.Exhibition, id),
         {:ok, _exhibition} <- Timesink.Repo.delete(exhibition) do
      {:noreply,
       socket
       |> assign(:showcases_active_and_upcoming, refresh_showcases())
       |> put_flash(:success, "Exhibition removed.")}
    else
      nil ->
        {:noreply, put_flash(socket, :error, "Exhibition not found.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove exhibition.")}
    end
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin")}
  end

  defp refresh_showcases() do
    Timesink.Repo.all(
      from s in Timesink.Cinema.Showcase,
        preload: [exhibitions: [:film, :theater]]
    )
    |> Enum.sort_by(fn s ->
      {
        showcase_rank(s.status),
        s.start_at || s.inserted_at
      }
    end)
  end

  defp showcase_rank(:active), do: 0
  defp showcase_rank(:upcoming), do: 1
  defp showcase_rank(:archived), do: 2
  defp showcase_rank(_), do: 3
end
