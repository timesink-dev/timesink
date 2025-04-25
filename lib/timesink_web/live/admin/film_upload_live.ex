defmodule TimesinkWeb.Admin.FilmUploadLive do
  use TimesinkWeb, :live_view
  alias Timesink.Cinema.Film
  alias Timesink.Storage.Mux
  alias Timesink.Storage.MuxUpload
  require Logger

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       films: Film.all(),
       selected_film_id: nil,
       upload_id: nil,
       upload_url: nil
     ), layout: {TimesinkWeb.Layouts, :film_upload}}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 space-y-8">
      <h2 class="text-2xl font-bold">Manage Films</h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <%= for film <- @films do %>
          <div
            phx-click="select_film"
            phx-value-id={film.id}
            class={[
              "border rounded-lg overflow-hidden shadow hover:shadow-lg cursor-pointer transition",
              @selected_film_id == film.id && "ring-2 ring-indigo-500"
            ]}
          >
            <div class="aspect-w-16 aspect-h-9 bg-gray-100">
              <%!-- <%= if film.poster_url do %>
                <img src={film.poster_url} alt={film.title} class="object-cover w-full h-full" />
              <% else %> --%>
              <div class="flex items-center justify-center h-full text-gray-400">No Poster</div>
              <%!-- <% end %> --%>
            </div>
            <div class="p-4 space-y-2">
              <h3 class="text-lg font-semibold">{film.title} ({film.year})</h3>
              <p class="text-sm text-gray-500">Duration: {film.duration} min</p>
              <p class="text-sm text-gray-700 line-clamp-2">{film.synopsis}</p>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @selected_film_id do %>
        <div class="mt-8 space-y-4">
          <h3 class="text-xl font-semibold">Selected Film Actions</h3>

          <%= if @selected_film && @selected_film.video_attachment_url do %>
            <div class="border p-4 rounded-lg bg-gray-50">
              <h4 class="mb-2 font-medium">Video Preview</h4>
              <mux-player
                playback-id={@selected_film.video_playback_id}
                metadata-video-title={@selected_film.title}
                stream-type="on-demand"
                class="w-full aspect-w-16 aspect-h-9"
              >
              </mux-player>
            </div>
          <% else %>
            <div class="border p-4 rounded-lg bg-yellow-50 text-yellow-700">
              No video uploaded yet.
            </div>

            <%= if is_nil(@upload_url) do %>
              <button
                phx-click="generate_upload_url"
                class="mt-4 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
              >
                Upload Video
              </button>
            <% else %>
              <div class="border mt-4 p-4 rounded-lg bg-white shadow">
                <h4 class="font-medium mb-2">Upload your video</h4>
                <script src="https://cdn.jsdelivr.net/npm/@mux/mux-uploader">
                </script>
                <mux-uploader
                  pausable
                  endpoint={@upload_url}
                  style="margin-top: 10px; border: 1px solid #ccc; padding: 20px; display: block;"
                >
                </mux-uploader>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("select_film", %{"id" => film_id}, socket) do
    {:noreply, assign(socket, selected_film_id: film_id, upload_url: nil, upload_id: nil)}
  end

  def handle_event(
        "generate_upload_url",
        _params,
        %{assigns: %{selected_film_id: film_id}} = socket
      ) do
    params = %{
      "cors_origin" => "*",
      "new_asset_settings" => %{
        "playback_policies" => ["public"],
        "video_quality" => "basic"
      }
    }

    Logger.debug("Generating Mux upload URL with params: #{inspect(params)}")

    with {:ok, %{"id" => upload_id, "url" => url} = _upload} <- Mux.generate_upload_url(params),
         {:ok, _mux_upload} <-
           Mux.create_mux_upload(%{
             "upload_id" => upload_id,
             "url" => url,
             "film_id" => film_id
           }) do
      {:noreply, assign(socket, upload_url: url, upload_id: upload_id)}
    else
      {:error, reason} ->
        Logger.error("Error generating upload: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to generate upload URL")}
    end
  end
end
