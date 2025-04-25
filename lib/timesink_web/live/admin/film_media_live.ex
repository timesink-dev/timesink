defmodule TimesinkWeb.Admin.FilmMediaLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Film

  def mount(_params, _session, socket) do
    films = Film |> Timesink.Repo.all() |> Timesink.Repo.preload([:poster, :video])

    {:ok,
     assign(socket,
       films: films,
       selected_film_id: nil
     ), layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-6 text-logo">Film Media Management</h1>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for film <- @films do %>
          <div class="border rounded-lg shadow-sm hover:shadow-md transition overflow-hidden">
            <div class="relative">
              <%= if film.poster do %>
                <img src={poster_url(film.poster)} alt={film.title} class="w-full h-48 object-cover" />
              <% else %>
                <div class="w-full h-48 bg-gray-200 flex items-center justify-center text-gray-500 text-sm">
                  No Poster Available
                </div>
              <% end %>
            </div>

            <div class="p-4">
              <h2 class="text-lg font-semibold">{film.title} ({film.year})</h2>
              <p class="text-sm text-gray-500 mb-2">{film.duration} min</p>
              <p class="text-sm text-gray-700 truncate">{film.synopsis}</p>

              <div class="flex items-center justify-between mt-4">
                <span class={
                  "text-xs font-semibold rounded px-2 py-1 " <>
                  if film.video, do: "bg-green-100 text-green-800", else: "bg-yellow-100 text-yellow-800"
                }>
                  {if film.video, do: "Video Uploaded", else: "No Video"}
                </span>

                <button
                  phx-click="manage_film"
                  phx-value-id={film.id}
                  class="bg-blue-500 hover:bg-blue-600 text-white text-xs px-3 py-1 rounded"
                >
                  Manage
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp poster_url(poster) do
    # Depending how you store paths...
    Routes.static_path(TimesinkWeb.Endpoint, poster.path)
  end

  def handle_event("manage_film", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/admin/film-media/#{id}")}
  end
end
