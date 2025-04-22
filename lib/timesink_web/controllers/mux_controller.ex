defmodule TimesinkWeb.MuxController do
  alias Ecto.UUID
  alias Timesink.Storage.MuxUpload
  use TimesinkWeb, :controller
  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.Blob
  alias Timesink.Cinema.Film
  alias Timesink.Storage.MuxUpload
  alias Timesink.Storage

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
  def handle_webhook(%{"type" => "video.asset.created", "data" => asset} = _params) do
    IO.puts("🎬 Mux asset.created webhook received")

    title = asset["meta"]["title"] || "Untitled"
    year = Date.utc_today().year

    film_params = %{
      title: title,
      year: year,
      # or extract from Mux metadata later
      duration: 25,
      color: :color,
      format: :digital,
      aspect_ratio: asset["aspect_ratio"] || "16:9",
      synopsis: "Uploaded via Mux"
    }

    with {:ok, film} <- maybe_create_film(film_params),
         {:ok, blob} <- create_mux_blob(asset),
         {:ok, _attachment} <- Storage.create_attachment(film, :video, blob) do
      IO.puts("🎞️ Attachment created and linked to film")
      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset.errors, label: "❌ Film creation failed with validation errors")
        {:error, :invalid_film}

      {:error, reason} ->
        IO.inspect(reason, label: "❌ Error in attachment pipeline")
        {:error, reason}
    end
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

  defp maybe_create_film(%{title: title, year: year} = params) do
    case Repo.get_by(Film, title: title, year: year) do
      nil ->
        %Film{}
        |> Film.changeset(params)
        |> Repo.insert()

      film ->
        {:ok, film}
    end
  end

  defp create_mux_blob(asset) do
    uri = asset["id"]
    metadata = %{"asset" => asset}

    blob_params = %{
      service: :s3,
      uri: uri,
      metadata: metadata
    }

    %Blob{}
    |> Blob.changeset(blob_params)
    |> Repo.insert()
  end
end
