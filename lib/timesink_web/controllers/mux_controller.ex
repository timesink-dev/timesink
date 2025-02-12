defmodule TimesinkWeb.MuxController do
  alias Timesink.Storage.MuxUpload
  use TimesinkWeb, :controller
  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.Blob
  alias Timesink.Storage.MuxUpload

  def it_works(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "It works!")
  end

  def webhook(conn, params) do
    Logger.debug("Mux webhook received", service: :mux, params: params)

    handle_webhook(params)

    conn |> resp(200, "OK")
  end

  @doc """
  Handle webhook requests from Mux.

  It's the main entrypoint for any webhook coming from Mux. It will handle
  different types of events and act accordingly.

  - [x] create a Blob out of a MuxUpload that's completed
  - [ ] update the MuxUpload with new status
  - [ ] handle asset deletions (type: "video.asset.deleted")
  """
  @spec handle_webhook(params :: map()) ::
          term()
  def handle_webhook(%{"type" => "video.asset.created"} = params) do
    asset = params["data"]

    Repo.transaction(fn ->
      new_blob_params = %{
        type: :mux,
        uri: asset["id"],
        metadata: %{"asset" => asset}
      }

      with {:ok, blob} <- Blob.create(new_blob_params),
           {:ok, mux_upload} <- MuxUpload.get_by(mux_id: asset["id"]),
           {:ok, _} <- MuxUpload.delete(mux_upload) do
        Logger.log("Blob created from Mux webhook",
          service: :mux,
          params: params,
          blob_id: blob.id,
          blob_uri: blob.uri,
          webhook_id: params["id"]
        )
      else
        {:error, :not_found} ->
          Logger.debug("MuxUpload not found while processing Mux webhook 'video.asset.created'",
            service: :mux,
            params: params
          )

        error ->
          Logger.error(error |> inspect(), service: :mux, params: params)
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
      Logger.log("MuxUpload status updated",
        service: :mux,
        params: params,
        mux_upload_id: mux_up.id,
        mux_upload_status: new_status
      )
    else
      error -> Logger.error(error |> inspect(), service: :mux, params: params)
    end
  end

  def handle_webhook(%{"type" => t} = params) when t in ["video.asset.errored"] do
    Logger.log("Mux: video asset error", service: :mux, params: params)
  end

  def handle_webhook(%{"type" => "video.asset.warning"} = params) do
    Logger.log("Mux: video asset warning", service: :mux, params: params)
  end

  def handle_webhook(_params), do: :ok
end
