defmodule TimesinkWeb.MuxController do
  use TimesinkWeb, :controller
  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.MuxUpload
  alias Timesink.Storage.Blob
  alias Timesink.Cinema.Film
  import Ecto.Query

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
    mux_metadata = %{
      "playback_id" => asset["playback_ids"],
      "asset_id" => asset["id"],
      "upload_id" => asset["upload_id"],
      "uploaded_at" => params["created_at"],
      "upload_title" => asset["meta"]["title"]
    }

    Repo.transaction(fn ->
      with {:ok, mux_upload} <- MuxUpload.get_by(upload_id: asset["upload_id"]),
           film_id when not is_nil(film_id) <- get_in(mux_upload.meta, ["film_id"]),
           {:ok, film} <- Film.get(film_id),
           {:ok, blob} <-
             Blob.create(%{
               uri: mux_upload.url,
               service: :mux,
               metadata: %{
                 "mux_asset" => mux_metadata,
                 "film_title" => film.title
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
    # temp solution - this film_id will be dynamically passed into these initial uploaad params to create a MuxUpload when uploading has started
    # so this webhook handling won't be needed once the client upload logic is setup

    mux_upload_params = %{
      upload_id: asset["id"],
      url: asset["url"],
      status: :asset_created,
      meta: %{
        "film_id" => "b65127c8-59bc-4f02-bc43-6e9eaf44dda8",
        "response" => asset
      }
    }

    with {:ok, _mux_upload} <- MuxUpload.create(mux_upload_params) do
      :ok
    else
      error -> Logger.error(error |> inspect(), service: :mux, params: params)
    end

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
      query =
        from(b in Blob,
          where: fragment("?->'mux_asset'->>'asset_id'", b.metadata) == ^asset["id"]
        )

      case Repo.one(query) do
        %Blob{} = blob ->
          case Blob.delete(blob) do
            {:ok, _} ->
              :ok

            {:error, reason} ->
              Logger.error(inspect(reason), service: :mux, params: params)
              Repo.rollback(reason)
          end

        nil ->
          Logger.error("No blob found for asset_id #{asset["id"]}", service: :mux, params: params)
          Repo.rollback(:not_found)
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
