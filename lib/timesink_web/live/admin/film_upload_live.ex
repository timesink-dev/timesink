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

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
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

      <%= if @selected_film_id && is_nil(@upload_url) do %>
        <button phx-click="generate_upload_url" class="generate-btn">
          Generate Upload URL
        </button>
      <% end %>

      <%= if  @upload_url do %>
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

    with {:ok, %{"id" => upload_id, "url" => url} = upload} <- Mux.generate_upload_url(params),
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
