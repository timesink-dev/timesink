defmodule TimesinkWeb.MuxController do
  alias Ecto.UUID
  alias Timesink.Storage.MuxUpload
  use TimesinkWeb, :controller
  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.Blob
  alias Timesink.Cinema.Film
  alias Timesink.Storage.MuxUpload

  def it_works(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "It works!")
  end

  def webhook(conn, params) do
    Logger.debug("Mux webhook received", service: :mux, params: params)

    webhook_key =
      Application.get_env(:timesink, Timesink.Storage.Mux)
      |> Keyword.get(:webhook_key)

    IO.inspect(webhook_key, label: "webhook_key")

    case params["webhook_key"] do
      ^webhook_key ->
        handle_webhook(params)
        conn |> resp(200, "OK")

      _ ->
        Logger.info("Invalid Mux webhook key", service: :mux, params: params)
        conn |> resp(403, "Forbidden")
    end
  end

  @doc """
  Handle webhook requests from Mux.

  It's the main entrypoint for any webhook coming from Mux. It will handle
  different types of events and act accordingly.
  """
  @spec handle_webhook(params :: map()) :: term()
  def handle_webhook(%{"type" => "video.asset.created"} = params) do
    asset = params["data"]

    film_params = %{
      title: "Bob",
      year: 2025,
      duration: 25,
      color: :color,
      aspect_ratio: asset["aspect_ratio"] || "16:9",
      format: :digital,
      synopsis: "Uploaded via Mux"
    }

    {:ok, film} = Film.create(film_params)

    Repo.transaction(fn ->
      new_blob_params = %{
        type: :mux,
        uri: asset["id"],
        metadata: %{"asset" => asset}
      }

      upload_id = asset["upload_id"] || asset["id"]

      with {:ok, blob} <- Blob.create(new_blob_params),
           {:ok, _attachment} <- Film.attach_video(film, blob) do
        Logger.info("🎞️ Attachment created and linked to film",
          film_id: film.id,
          blob_id: blob.id,
          mux_asset_id: asset["id"]
        )

        case MuxUpload.get_by(mux_id: upload_id) do
          {:ok, mux_upload} ->
            {:ok, _} = MuxUpload.delete(mux_upload)
            Logger.debug("Deleted MuxUpload entry #{mux_upload.id}")

          {:error, :not_found} ->
            Logger.debug("No MuxUpload found for mux_id=#{upload_id}, skipping delete")
        end
      else
        error ->
          Logger.error("Failed to handle video.asset.created: #{inspect(error)}")
          Repo.rollback(error)
      end
    end)
  end

  def handle_webhook(%{"type" => type} = params)
      when type in ["video.upload.errored", "video.upload.cancelled"] do
    asset = params["data"]

    new_status =
      case type do
        "video.upload.errored" -> :errored
        "video.upload.cancelled" -> :cancelled
      end

    with {:ok, mux_up} <- MuxUpload.get_by(mux_id: asset["id"]),
         {:ok, _} <- MuxUpload.update(mux_up, %{status: new_status}) do
      Logger.info("MuxUpload status updated",
        service: :mux,
        params: params,
        mux_upload_id: mux_up.id,
        mux_upload_status: new_status
      )
    else
      error -> Logger.error(error |> inspect(), service: :mux, params: params)
    end
  end

  def handle_webhook(%{"type" => "video.asset.errored"} = params) do
    Logger.error("Mux: video asset error", service: :mux, params: params)
  end

  def handle_webhook(%{"type" => "video.asset.warning"} = params) do
    Logger.warning("Mux: video asset warning", service: :mux, params: params)
  end

  def handle_webhook(_params), do: :ok
end
