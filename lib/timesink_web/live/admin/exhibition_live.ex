defmodule TimesinkWeb.Admin.ExhibitionsLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.Film
  import Ecto.Query

  def mount(_params, _session, socket) do
    showcases =
      Timesink.Repo.all(
        from s in Timesink.Cinema.Showcase,
          preload: [exhibitions: [:film, :theater]]
      )

    theaters =
      Timesink.Cinema.Theater
      |> Timesink.Repo.all()

    films = Film.all()

    {:ok, assign(socket, showcases: showcases, films: films, theaters: theaters),
     layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-8">
      <!-- Sidebar with films -->
      <div class="w-1/4 border-r p-4">
        <h2 class="font-bold mb-2">Films</h2>
        <%= for film <- @films do %>
          <div
            id={"film-#{film.id}"}
            class="bg-gray-200 rounded px-2 py-1 mb-1 cursor-move text-black"
            draggable="true"
            phx-hook="Draggable"
            data-film-id={film.id}
          >
            {film.title}
          </div>
        <% end %>
      </div>
      
    <!-- Showcase + Theaters -->
      <div class="flex-1 p-4 space-y-6">
        <%= for showcase <- @showcases do %>
          <div class="border p-4 rounded shadow">
            <h3 class="font-bold text-lg mb-2">{showcase.title}</h3>
            <div class="grid grid-cols-3 gap-4">
              <%= for theater <- @theaters do %>
                <div
                  id={"theater-#{theater.id}-showcase-#{showcase.id}"}
                  class="border border-dashed rounded p-4 min-h-[100px]"
                  phx-hook="DropZone"
                  data-showcase-id={showcase.id}
                  data-theater-id={theater.id}
                >
                  <p class="text-sm font-semibold mb-1">{theater.name}</p>

                  <%= for exhibition <- showcase.exhibitions,
              exhibition.theater_id == theater.id do %>
                    <div class="bg-blue-100 rounded px-2 py-1 text-sm mt-1 text-black">
                      🎬 {exhibition.film.title}
                    </div>
                  <% end %>

                  <%= if Enum.empty?(Enum.filter(showcase.exhibitions, &(&1.theater_id == theater.id))) do %>
                    <p class="text-gray-500">Drop films here</p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
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
        showcases =
          Timesink.Repo.all(
            from s in Timesink.Cinema.Showcase,
              preload: [exhibitions: [:film, :theater]]
          )

        {:noreply,
         socket
         |> assign(:showcases, showcases)
         |> put_flash(:info, "Exhibition added.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add exhibition.")}
    end
  end
end
