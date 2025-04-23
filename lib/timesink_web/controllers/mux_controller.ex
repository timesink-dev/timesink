defmodule TimesinkWeb.MuxController do
  use TimesinkWeb, :controller
  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.MuxUpload
  alias Timesink.Storage.Blob
  alias Timesink.Cinema.Film

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
  def handle_webhook(%{"type" => "video.asset.ready", "data" => asset} = params) do
    title = asset["meta"]["title"] || "Untitled"
    # temporary solution (film will already have been instantiaed via backpex admin panel)
    year = Date.utc_today().year

    _film_params = %{
      title: title,
      year: year,
      # or extract from Mux metadata later
      duration: 25,
      color: :color,
      format: :digital,
      aspect_ratio: asset["aspect_ratio"] || "16:9",
      synopsis: "Uploaded via Mux"
    }

    metadata = %{
      "mux_asset" => %{
        "playback_id" => asset["playback_ids"],
        "asset_id" => asset["id"],
        "upload_id" => asset["upload_id"],
        "uploaded_at" => params["created_at"]
      }
    }

    blob_params = %{
      service: :mux,
      uri: asset["id"],
      metadata: metadata
    }

    # for testing purposes

    Repo.transaction(fn ->
      with {:ok, mux_upload} <- MuxUpload.get_by(upload_id: asset["upload_id"]),
           film_id when not is_nil(film_id) <- get_in(mux_upload.meta, ["film_id"]),
           {:ok, film} <- Film.get(film_id),
           {:ok, blob} <-
             Blob.create(%{
               uri: mux_upload.url,
               service: :mux,
               metadata: %{
                 "mux_asset" => %{
                   "playback_id" => asset["playback_ids"],
                   "asset_id" => asset["id"],
                   "upload_id" => asset["upload_id"],
                   "uploaded_at" => params["created_at"],
                   "title" => film.title
                 }
               }
             }),
           {:ok, _attachment} <- Film.attach_video(film, blob),
           {:ok, _} <- MuxUpload.delete(mux_upload) do
        :ok
      else
        error ->
          Logger.error(error |> inspect(), service: :mux, params: params)
          Repo.rollback(error)
      end
    end)
  end

  def handle_webhook(%{"type" => "video.upload.created", "data" => asset} = params) do
    IO.inspect(params, label: "Video Upload Created")

    MuxUpload.create(%{
      upload_id: asset["id"],
      url: asset["url"],
      status: :asset_created,
      meta: %{
        "film_id" => "b65127c8-59bc-4f02-bc43-6e9eaf44dda8",
        "response" => asset
      }
    })
  end

  def handle_webhook(%{"type" => type} = params)
      when type in ["video.upload.errored", "video.upload.cancelled"] do
    asset = params["data"]

    new_status =
      case type do
        "video.upload.errored" -> :errored
        "video.upload.cancelled" -> :cancelled
      end

    with {:ok, mux_upload} <- MuxUpload.get_by(upload_id: asset["id"]),
         {:ok, _} <- MuxUpload.update(mux_upload, %{status: new_status}) do
      Logger.info("MuxUpload status updated",
        service: :mux,
        params: params,
        mux_upload_id: mux_upload.id,
        mux_upload_status: new_status
      )
    else
      error -> Logger.error(error |> inspect(), service: :mux, params: params)
    end
  end

  def handle_webhook(%{"type" => "video.asset.deleted", "data" => asset} = params) do
    Repo.transaction(fn ->
      with {:ok, blob} <- Blob.get_by(uri: asset["id"]),
           {:ok, _} <- Blob.delete(blob) do
      else
        error ->
          Logger.error(error |> inspect(), service: :mux, params: params)
          Repo.rollback(error)
      end
    end)
  end

  def handle_webhook(%{"type" => "video.asset.errored"} = params) do
    Logger.error("Mux: video asset error", service: :mux, params: params)
  end

  def handle_webhook(%{"type" => "video.asset.warning"} = params) do
    Logger.warning("Mux: video asset warning", service: :mux, params: params)
  end

  def handle_webhook(_params), do: :ok
end
