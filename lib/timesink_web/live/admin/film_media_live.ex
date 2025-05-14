defmodule TimesinkWeb.Admin.FilmMediaLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Film

  def mount(_params, _session, socket) do
    films = Film |> Timesink.Repo.all() |> Timesink.Repo.preload(video: [:blob], poster: [:blob])

    {:ok,
     assign(socket,
       films: films,
       selected_film_id: nil
     ), layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 min-h-screen space-y-10">
      <.button color="none" class="mt-6 p-0 text-center" phx-click="go_back">
        ← Back to Admin console
      </.button>
      <h1 class="text-4xl font-bold text-center mb-12">Film Catalogue Media Management</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-10">
        <%= for film <- @films do %>
          <div
            phx-click="manage_film"
            phx-value-id={film.id}
            class="cursor-pointer bg-obsidian bg-opacity-60 border border-dark-theater-medium hover:border-neon-blue-lightest hover:shadow-lg hover:scale-[1.02] transition-all duration-300 ease-in-out rounded-2xl overflow-hidden shadow-md group h-[28rem]"
          >
            <div class="relative">
              <%= if film.poster do %>
                <img
                  src={Film.poster_url(film.poster)}
                  alt={film.title}
                  class="w-full h-64 object-cover group-hover:opacity-90 transition"
                />
              <% else %>
                <div class="w-full h-64 bg-obsidian flex items-center justify-center text-dark-theater-light text-lg">
                  No Poster Available
                </div>
              <% end %>
            </div>

            <div class="px-6 pt-6 space-y-2 bg-backroom-black h-full">
              <h2 class="text-2xl font-semibold text-mystery-white">{film.title}</h2>
              <p class="text-mystery-white text-sm">{film.year} • {film.duration} min</p>
              <p class="text-sm text-mystery-white truncate">{film.synopsis}</p>

              <div class="mt-4">
                <span class={
              "inline-block text-xs font-semibold rounded-full px-3 py-1 " <>
              if film.video,
                do: "bg-green-600 text-green-100",
                else: "bg-yellow-500 text-yellow-100"
            }>
                  {if film.video, do: "Video Uploaded", else: "No Video"}
                </span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin")}
  end

  def handle_event("manage_film", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/admin/film-media/#{id}")}
  end
end
