defmodule TimesinkWeb.Admin.FilmMediaShowLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Film
  alias Timesink.Storage
  alias Timesink.Repo
  require Logger

  def mount(%{"id" => film_id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Timesink.PubSub, "film_media:#{film_id}")

    film =
      Repo.get!(Film, film_id)
      |> Repo.preload(video: [:blob], poster: [:blob])

    {:ok, assign(socket, film: film, upload_url: nil, upload_id: nil, notification: nil),
     layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 bg-dark-room-theater-lightest min-h-screen text-dark-room-theater-primary space-y-12">
      <.button color="none" class="mt-6 p-0 text-center" phx-click="go_back">
        ← Back
      </.button>
      <!-- Film Header -->
      <div class="space-y-3 text-center max-w-3xl mx-auto">
        <h1 class="text-4xl font-bold">{@film.title}</h1>
        <p class="text-lg text-dark-room-theater-light">{@film.year}</p>

        <%= if @film.synopsis do %>
          <p class="mt-2 text-base text-dark-room-theater-light/80 leading-relaxed">
            {@film.synopsis}
          </p>
        <% end %>
      </div>
      
    <!-- Poster Section -->
      <section class="bg-dark-room-theater-light rounded-2xl shadow-lg p-8 flex flex-col items-center">
        <h2 class="text-2xl font-semibold mb-6">Poster</h2>

        <%= if @film.poster do %>
          <img
            src={poster_url(@film.poster)}
            alt="Poster"
            class="rounded-lg w-full max-w-md object-cover shadow-md"
          />
        <% else %>
          <div class="flex flex-col items-center justify-center w-full h-80 bg-dark-room-theater-lightest rounded-lg border-2 border-dashed border-dark-room-theater-light text-dark-room-theater-primary/70">
            <.icon name="hero-document" class="h-16 w-16" />
            <p class="mt-4 text-lg">No poster uploaded yet</p>
          </div>
        <% end %>
      </section>
      
    <!-- Video Section -->
      <section class="bg-dark-room-theater-light rounded-2xl shadow-lg p-8 flex flex-col items-center">
        <h2 class="text-2xl font-semibold mb-6">Video</h2>

        <%= if playback_id = get_mux_playback_id(@film.video) do %>
          <mux-player
            playback-id={playback_id}
            metadata-video-title={@film.title}
            style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 12px; overflow: hidden;"
            stream-type="on-demand"
          />
          <button
            class="mt-6 bg-red-600 hover:bg-red-700 text-white font-medium px-6 py-3 rounded-lg transition"
            phx-click="remove_video"
          >
            Remove Video
          </button>
        <% else %>
          <div class="flex flex-col items-center w-full">
            <%= if @upload_url do %>
              <div class="text-green-400 mb-4 font-medium text-center">
                Upload URL ready. Drag or drop your video below!
              </div>
              <mux-uploader
                pausable
                endpoint={@upload_url}
                style="display: block; width: 100%; border: 2px dashed #999; padding: 30px; border-radius: 12px; background-color: rgba(255,255,255,0.05);"
              />
            <% else %>
              <button
                phx-click="generate_upload_url"
                class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-6 py-3 rounded-lg transition"
              >
                Generate Upload Link
              </button>
            <% end %>
          </div>
        <% end %>
      </section>
      
    <!-- Flash Messages -->
      <%= if @notification do %>
        <div class="space-y-4 mt-8">
          <%= case @notification do %>
            <% {:info, message} -> %>
              <div class="bg-green-100/10 border border-green-300/30 text-green-300 px-4 py-3 rounded-lg text-center">
                {message}
              </div>
            <% {:error, message} -> %>
              <div class="bg-red-100/10 border border-red-300/30 text-red-300 px-4 py-3 rounded-lg text-center">
                {message}
              </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("generate_upload_url", _params, %{assigns: %{film: film}} = socket) do
    params = %{
      "cors_origin" => "*",
      "new_asset_settings" => %{
        "playback_policies" => ["public"],
        "video_quality" => "basic"
      }
    }

    with {:ok, %{"id" => upload_id, "url" => url} = _upload} <-
           Storage.Mux.generate_upload_url(params),
         {:ok, _mux_upload} <-
           Storage.Mux.create_mux_upload(%{
             "upload_id" => upload_id,
             "url" => url,
             "film_id" => film.id
           }) do
      {:noreply,
       socket
       |> assign(
         upload_url: url,
         upload_id: upload_id
       )}
    else
      {:error, reason} ->
        Logger.error("Error generating upload URL: #{inspect(reason)}")
        {:noreply, assign(socket, notification: {:error, "Failed to generate upload URL."})}
    end
  end

  def handle_event("remove_video", _params, socket) do
    film = socket.assigns.film

    with {:ok, _} <-
           Timesink.Storage.Mux.delete_asset(film.video.blob.metadata["mux_asset"]["asset_id"]) do
      socket
      |> assign(film: load_film(film.id))
      |> assign(notification: {:info, "Video removed successfully!"})

      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error("Error removing video: #{inspect(reason)}")
        {:noreply, assign(socket, notification: {:error, "Failed to remove video."})}
    end
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/film-media")}
  end

  def handle_info(%{event: "video_ready"}, socket) do
    Logger.info("Received video_ready PubSub event, reloading film...")

    film = load_film(socket.assigns.film.id)

    {:noreply,
     socket
     |> assign(film: film, notification: {:info, "Video uploaded and ready to view! 🎬"})}
  end

  def handle_info(%{event: "video_deleted"}, socket) do
    Logger.info("Received video_deleted PubSub event, reloading film...")

    film = load_film(socket.assigns.film.id)

    {:noreply,
     socket
     |> assign(film: film, notification: {:info, "Video deleted successfully!"})}
  end

  defp poster_url(poster) do
    Phoenix.VerifiedRoutes.static_path(TimesinkWeb.Endpoint, poster.path)
  end

  defp get_mux_playback_id(nil), do: nil

  defp get_mux_playback_id(%Timesink.Storage.Attachment{blob: %{metadata: metadata}}) do
    metadata
    |> Map.get("mux_asset", %{})
    |> Map.get("playback_id", [])
    |> List.first()
    |> case do
      nil -> nil
      %{"id" => id} -> id
      _ -> nil
    end
  end

  defp get_mux_playback_id(_), do: nil

  defp load_film(film_id) do
    Film
    |> Repo.get!(film_id)
    |> Repo.preload(video: [:blob], poster: [:blob])
  end
end
