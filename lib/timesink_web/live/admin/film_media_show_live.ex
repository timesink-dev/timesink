defmodule TimesinkWeb.Admin.FilmMediaShowLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Film
  alias Timesink.Storage
  alias Timesink.Repo
  require Logger

  def mount(%{"id" => film_id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Timesink.PubSub, "film_media:#{film_id}")

    film =
      Film.get!(film_id)
      |> Repo.preload(video: [:blob], poster: [:blob], trailer: [:blob])

    {:ok,
     assign(socket,
       film: film,
       upload_url: nil,
       upload_id: nil,
       notification: nil
     )
     |> allow_upload(:poster,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000
     ), layout: {TimesinkWeb.Layouts, :film_upload}}
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
        <p class="text-lg text-dark-room-ter-light">{@film.year}</p>

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
            src={Film.poster_url(@film.poster)}
            alt="Poster"
            class="rounded-lg w-full max-w-md object-cover shadow-md"
          />
          <button
            phx-click="remove_poster"
            class="mt-4 bg-red-600 hover:bg-red-700 text-white font-medium px-4 py-2 rounded"
          >
            Remove Poster
          </button>
        <% else %>
          <div class="flex flex-col items-center justify-center w-full h-auto min-h-80 bg-dark-room-theater-lightest rounded-lg border-2 border-dashed border-dark-room-theater-light text-dark-room-theater-primary/70 px-4 py-6">
            <.icon name="hero-document" class="h-16 w-16" />
            <p class="mt-4 text-lg">No poster uploaded yet</p>

            <form
              phx-submit="upload_poster"
              phx-change="validate_poster"
              phx-drop-target={@uploads.poster.ref}
              class="mt-4 flex flex-col items-center w-full"
            >
              <.live_file_input upload={@uploads.poster} class="mb-4 mx-auto" />

              <div
                :for={entry <- @uploads.poster.entries}
                class="flex flex-col items-center w-full max-w-xs"
              >
                <div class="w-full aspect-square overflow-hidden rounded shadow-md mb-2 bg-gray-800">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                </div>

                <figcaption class="text-sm text-center mb-2">{entry.client_name}</figcaption>

                <div class="w-full">
                  <progress value={entry.progress} max="100" class="w-full h-2 rounded bg-gray-700">
                    {entry.progress}%
                  </progress>
                  <p class="text-xs text-center mt-1 text-dark-room-theater-light">
                    {entry.progress}%
                  </p>
                </div>

                <p
                  :for={err <- upload_errors(@uploads.poster, entry)}
                  class="text-red-500 text-sm mt-1"
                >
                  {error_to_string(err)}
                </p>
              </div>

              <button
                type="submit"
                class="mt-6 bg-blue-500 hover:bg-blue-600 text-white font-semibold px-6 py-2 rounded"
              >
                Upload Poster
              </button>
            </form>
          </div>
        <% end %>
      </section>

    <!-- Video Section -->
      <section class="bg-dark-room-theater-light rounded-2xl shadow-lg p-8 flex flex-col items-center">
        <h2 class="text-2xl font-semibold mb-6">Video</h2>

        <%= if playback_id = Film.get_mux_playback_id(@film.video) do %>
          <mux-player
            playback-id={playback_id}
            metadata-video-title={@film.title}
            style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 12px; overflow: hidden;"
            stream-type="on-demand"
          />
          <button
            class="mt-6 bg-red-600 hover:bg-red-700 text-backroom-black font-bold px-6 py-3 rounded-lg transition"
            phx-click="remove_film_media"
            phx-value-type="video"
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

    <!-- Trailer Section -->
      <section class="bg-dark-room-theater-light rounded-2xl shadow-lg p-8 flex flex-col items-center">
        <h2 class="text-2xl font-semibold mb-6">Trailer</h2>

        <%= if playback_id = Film.get_mux_playback_id(@film.trailer) do %>
          <mux-player
            playback-id={playback_id}
            metadata-video-title={@film.title}
            style="width: 100%; max-width: 800px; aspect-ratio: 16/9; border-radius: 12px; overflow: hidden;"
            stream-type="on-demand"
          />
          <button
            class="mt-6 bg-red-600 hover:bg-red-700 text-backroom-black font-bold px-6 py-3 rounded-lg transition"
            phx-click="remove_film_media"
            phx-value-type="trailer"
          >
            Remove Trailer
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
                phx-value-is_trailer="true"
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

  def handle_event(
        "generate_upload_url",
        %{"is_trailer" => "true"},
        %{assigns: %{film: film}} = socket
      ) do
    create_mux_upload(socket, film, true)
  end

  def handle_event("generate_upload_url", _params, %{assigns: %{film: film}} = socket) do
    create_mux_upload(socket, film, false)
  end

  def handle_event("remove_film_media", %{"type" => type}, socket) do
    film = socket.assigns.film

    asset =
      case type do
        "trailer" -> film.trailer
        _ -> film.video
      end

    with %Timesink.Storage.Blob{} = blob <- asset.blob,
         %{"asset_id" => asset_id} <- blob.metadata["mux_asset"],
         {:ok, _} <- Timesink.Storage.Mux.delete_asset(asset_id) do
      {:noreply,
       socket
       |> assign(film: load_film(film.id))
       |> assign(notification: {:info, "#{String.capitalize(type)} removed successfully!"})}
    else
      nil ->
        {:noreply, assign(socket, notification: {:error, "No #{type} asset to remove."})}

      {:error, reason} ->
        Logger.error("Error removing #{type}: #{inspect(reason)}")
        {:noreply, assign(socket, notification: {:error, "Failed to remove #{type}."})}
    end
  end

  def handle_event("upload_poster", _params, socket) do
    %{film: film, uploads: %{poster: _upload}} = socket.assigns

    consume_uploaded_entries(socket, :poster, fn %{path: path}, entry ->
      upload = %Plug.Upload{
        filename: entry.client_name,
        content_type: entry.client_type || MIME.from_path(entry.client_name),
        path: path
      }

      Storage.create_attachment(film, :poster, upload)
    end)

    {:noreply,
     socket
     |> assign(film: load_film(film.id))
     |> put_flash(:info, "Poster uploaded successfully.")}
  end

  def handle_event("validate_poster", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove_poster", _params, socket) do
    film = socket.assigns.film

    with %Timesink.Storage.Attachment{} = poster <- film.poster,
         {:ok, :deleted} <- Timesink.Storage.delete_attachment(poster) do
      {:noreply,
       socket
       |> assign(film: load_film(film.id))
       |> put_flash(:info, "Poster removed successfully.")}
    else
      nil ->
        {:noreply, put_flash(socket, :error, "No poster found to remove.")}

      {:error, reason} ->
        Logger.error("Failed to delete poster: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to remove poster.")}
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

  defp create_mux_upload(socket, film, is_trailer) do
    params = %{
      "cors_origin" => "*",
      "new_asset_settings" => %{
        "playback_policies" => ["public"],
        "video_quality" => "basic"
      }
    }

    with {:ok, %{"id" => upload_id, "url" => url}} <- Storage.Mux.generate_upload_url(params),
         {:ok, _mux_upload} <-
           Storage.Mux.create_mux_upload(%{
             "upload_id" => upload_id,
             "url" => url,
             "film_id" => film.id,
             "is_trailer" => is_trailer
           }) do
      {:noreply, assign(socket, upload_url: url, upload_id: upload_id)}
    else
      {:error, reason} ->
        Logger.error("Error generating upload URL: #{inspect(reason)}")
        {:noreply, assign(socket, notification: {:error, "Failed to generate upload URL."})}
    end
  end

  defp load_film(film_id) do
    Film
    |> Repo.get!(film_id)
    |> Repo.preload(video: [:blob], poster: [:blob], trailer: [:blob])
  end

  defp error_to_string(:too_large), do: "File too large"
  defp error_to_string(:not_accepted), do: "File type not allowed"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end
