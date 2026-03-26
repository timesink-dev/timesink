defmodule TimesinkWeb.Cinema.FilmLive do
  use TimesinkWeb, :live_view

  import TimesinkWeb.Components.FilmInfo

  alias Timesink.{Repo}
  alias Timesink.Cinema.{Film, Exhibition}
  import Ecto.Query

  @impl true
  def mount(%{"title" => title_param, "director" => director_param} = params, _session, socket) do
    from_theater = Map.get(params, "from") == "theater"

    film = find_film_by_slugs(title_param, director_param)

    case film do
      nil ->
        {:ok, assign(socket, not_found: true, from_theater: false, current_path: "/")}

      %Film{} ->
        trailer_playback_id = Film.get_mux_playback_id(film.trailer)
        poster_url = Film.poster_url(film.poster)

        # Find the active theater slug for this film (if currently playing)
        theater_slug =
          from(e in Exhibition,
            join: t in assoc(e, :theater),
            join: s in assoc(e, :showcase),
            where: e.film_id == ^film.id and s.status == :active,
            select: t.slug,
            limit: 1
          )
          |> Repo.one()

        # Redirect logged-in users straight to the theater if they came from that button
        if from_theater && socket.assigns[:current_user] && theater_slug do
          {:ok, push_navigate(socket, to: "/now-playing/#{theater_slug}")}
        else
          current_path = current_film_path(film, params)

          {:ok,
           assign(socket,
             film: film,
             trailer_playback_id: trailer_playback_id,
             poster_url: poster_url,
             not_found: false,
             from_theater: from_theater,
             theater_slug: theater_slug,
             current_path: current_path
           )}
        end
    end
  end

  @impl true
  def render(%{not_found: true} = assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-16">
      <div class="max-w-3xl mx-auto text-center">
        <h1 class="text-xl md:text-2xl font-semibold text-mystery-white">Film not found</h1>
        <p class="mt-3 text-zinc-400">We couldn't find that film.</p>
        <.link navigate={~p"/"} class="inline-block mt-6 text-neon-blue-lightest hover:opacity-80">
          Back to home
        </.link>
      </div>
    </section>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="px-4 md:px-6 pb-20">
      <div class="mx-auto max-w-4xl mt-12 md:mt-16">
        
    <!-- Poster + Trailer -->
        <div class="rounded-2xl overflow-hidden bg-backroom-black border border-zinc-800">
          <%= if @trailer_playback_id do %>
            <div class="aspect-video w-full bg-black">
              <mux-player
                stream-type="on-demand"
                playback-id={@trailer_playback_id}
                metadata-video-title={@film.title}
                poster={@poster_url}
                class="w-full h-full"
              >
              </mux-player>
            </div>
          <% else %>
            <%= if @poster_url do %>
              <div class="relative w-full aspect-[2/3] sm:aspect-video max-h-[520px] overflow-hidden">
                <img
                  src={@poster_url}
                  alt={@film.title}
                  class="w-full h-full object-cover object-top"
                />
                <div class="absolute inset-0 bg-linear-to-t from-backroom-black/80 via-transparent to-transparent">
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
        
    <!-- Member gate -->
        <%= if is_nil(@current_user) && @from_theater do %>
          <div class="mt-5 rounded-2xl ring-1 ring-zinc-800 bg-white/2 px-6 py-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-mystery-white">
                This film is playing live in the theater.
              </p>
              <p class="text-sm text-zinc-400 mt-0.5">Only members are currently allowed inside.</p>
            </div>
            <div class="shrink-0 flex items-center gap-3">
              <.link
                navigate={"/sign-in?return_to=#{URI.encode(@current_path)}"}
                class="inline-flex items-center justify-center rounded bg-white text-backroom-black px-5 py-2 text-sm font-medium transition hover:opacity-90"
              >
                Sign in
              </.link>
              <span class="text-xs text-zinc-500">or</span>
              <.link
                navigate={~p"/join"}
                class="text-sm text-gray-400 hover:opacity-80 transition-opacity"
              >
                Become a member now!
              </.link>
            </div>
          </div>
        <% end %>
        
    <!-- Film info -->
        <div class="mt-5 rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800 px-6 py-8">
          <.film_info film={@film} class="mt-0 border-none pt-0" />
        </div>

        <div class="mt-10">
          <.film_review film={@film} />
        </div>
      </div>
    </section>
    """
  end

  # Generate a URL-friendly slug from a string
  def title_slug(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  def director_slug(%{creative: %{last_name: l}}) do
    title_slug(l)
  end

  # Pick the canonical director for URL purposes: last alphabetically by last name
  defp canonical_director([]), do: nil

  defp canonical_director(directors) do
    Enum.max_by(directors, fn %{creative: c} ->
      String.downcase(c.last_name || "")
    end)
  end

  # Return the canonical path for a film (requires directors preloaded)
  def film_path(%Film{} = film) do
    dir_slug =
      case canonical_director(film.directors || []) do
        nil -> "unknown"
        director -> director_slug(director)
      end

    "/films/#{title_slug(film.title)}/#{dir_slug}"
  end

  # Find a film by matching title slug and director slug
  defp find_film_by_slugs(title_param, director_param) do
    Film
    |> Repo.all()
    |> Enum.find(fn f ->
      title_slug(f.title) == title_param
    end)
    |> case do
      nil ->
        nil

      f ->
        preloaded =
          Repo.preload(f, [
            :genres,
            poster: [:blob],
            trailer: [:blob],
            directors: [creative: :user],
            writers: [creative: :user],
            producers: [creative: :user],
            cast: [creative: :user],
            crew: [creative: :user]
          ])

        dir_slug =
          case canonical_director(preloaded.directors) do
            nil -> "unknown"
            director -> director_slug(director)
          end

        if dir_slug == director_param do
          preloaded
        else
          nil
        end
    end
  end

  # Build the current page's path including query params, used for return_to after login
  defp current_film_path(%Film{} = film, params) do
    base = film_path(film)
    if Map.get(params, "from") == "theater", do: base <> "?from=theater", else: base
  end
end
