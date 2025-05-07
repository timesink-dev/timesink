defmodule TimesinkWeb.Cinema.TheaterLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema

  def render(assigns) do
    ~H"""
    <div id="theater" class="max-w-4xl mx-auto p-6 space-y-8 text-gray-100">
      <div class="border-b border-gray-700 pb-4">
        <h1 class="text-3xl font-bold text-white">{@theater.name}</h1>
        <p class="text-gray-400 mt-2">{@theater.description}</p>
      </div>

      <div>
        <h2 class="text-2xl font-semibold text-gray-200 mb-2">Now Playing:</h2>
        <div class="bg-dark-theater-primary rounded-lg p-4 shadow-md border border-gray-700">
          <h3 class="text-xl font-bold text-white">
            {@film.title}
            <span class="text-gray-400">({@film.year})</span>
          </h3>

          <%!-- <p class="text-gray-300 mt-1">by <%= @film.author %></p> --%>
          <%!-- <%= if @film.poster_url do %>
            <img src={@film.poster_url} alt="Film Poster" class="mt-4 rounded-lg w-64 shadow-lg" />
          <% end %> --%>
        </div>
      </div>

      <div class="text-sm text-gray-500 italic">
        More interactive features (chat, playback, etc.) coming soon.
      </div>
    </div>
    """
  end

  def mount(%{"theater_slug" => theater_slug}, _session, socket) do
    with {:ok, theater} <- Cinema.get_theater_by_slug(theater_slug),
         {:ok, showcase} <- Cinema.get_active_showcase(),
         {:ok, exhibition} <-
           Cinema.get_exhibition_for_theater_and_showcase(theater.id, showcase.id),
         {:ok, film} <- Cinema.get_film_by_id(exhibition.film_id) do
      {:ok,
       socket
       |> assign(:theater, theater)
       |> assign(:film, film)
       |> assign(:exhibition, exhibition)}
    else
      _ -> {:redirect, socket |> put_flash(:error, "Not found") |> redirect(to: "/")}
    end
  end
end
