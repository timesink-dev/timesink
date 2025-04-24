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
       upload_id: "DVYsmLKtUQ2wV0102oNLgUcq4Trh9l2sau5LUbLlRneLw",
       upload_url:
         "https://storage.googleapis.com/video-storage-gcp-us-east1-vop1-uploads/HsgozA4L2kJuu8rl3OFH3B?Expires=1745493667&GoogleAccessId=uploads-gcp-us-east1-vop1%40mux-video-production.iam.gserviceaccount.com&Signature=YWqWUtKo0KTiyDlxT%2Fl1%2BX1MsUahUm3w9uxEKYjgIFRqPtzwdCpQWlDvoP9DfnvxBTm4ndx1ZbVeOKQcb%2BelM5PBEnA2G6nZdUzWfmxVeiUd0IbZzhmZBMpRP7odX5caqdNnd5As9jq1Wy7hI6RhLhIeCKTAdRQUXaKHgLw%2ByU4szsvPTxAXZL%2FC0FKtOdSTnEirAS3VU1Ni%2FblFLDGdRwtItOKTshw8Tq5MzIHovlA4TEZG8ANJYpwfSxRCCoQPlE68B7V4TmRLwpDui7hvt%2BHhGsLWMuyU7c813kR%2FVAHJJTY8s6ptsRznM14wVOo1F%2FhsinQ96sGAZ%2Bfy1%2BYXtw%3D%3D&upload_id=AAO2VwpvKCxGS_1Njao2HH423HvQ-r3Ovi1Tc1ewHugKw32hRiVj7k9PHYalKdZWr-whVIShC98nHJSsIPb4a85q0E0jSbIPIsrRbnZdLlC0XoM"
     ), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h2>Select a Film</h2>
      <ul>
        <%= for film <- @films do %>
          <li>
            <strong>{film.title}</strong>
            <button
              type="button"
              phx-click="select_film"
              phx-value-id={film.id}
              class={if @selected_film_id == film.id, do: "selected", else: ""}
            >
              Select
            </button>
          </li>
        <% end %>
      </ul>

      <%= if @selected_film_id && @upload_url do %>
        <button phx-click="generate_upload_url" class="generate-btn">
          Generate Upload URL
        </button>
      <% end %>

      <%= if @upload_url do %>
        <script src="https://cdn.jsdelivr.net/npm/@mux/mux-uploader">
        </script>
        <mux-uploader
          pausable
          endpoint={@upload_url}
          style="margin-top: 20px; border: 1px solid #ccc; padding: 20px; display: block;"
        >
        </mux-uploader>
      <% end %>
    </div>
    """
  end

  def handle_event("select_film", %{"id" => film_id}, socket) do
    {:noreply,
     assign(socket,
       selected_film_id: film_id,
       upload_url: socket.assigns.upload_url,
       upload_id: socket.assigns.upload_id
     )}
  end

  def handle_event(
        "generate_upload_url",
        _params,
        %{assigns: %{selected_film_id: film_id, upload_url: upload_url, upload_id: upload_id}} =
          socket
      ) do
    params = %{
      # Replace with actual origin in production
      "cors_origin" => "*",
      "new_asset_settings" => %{
        # Note: it should be plural, not "playback_policy"
        "playback_policies" => ["public"],
        "video_quality" => "basic"
      }
    }

    Logger.debug("Generating Mux upload URL with params: #{inspect(params)}")

    IO.inspect(upload_url, label: "Upload URL")
    IO.inspect(upload_id, label: "Upload ID")
    IO.inspect(film_id, label: "Film ID")

    with {:ok, _mux_upload} <-
           Mux.create_mux_upload(%{
             "upload_id" => upload_id,
             "url" => upload_url,
             "film_id" => film_id
           }) do
      {:noreply, assign(socket, upload_url: upload_url, upload_id: upload_id)}
    else
      {:error, reason} ->
        Logger.error("Error generating upload: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to generate upload URL")}
    end
  end
end
