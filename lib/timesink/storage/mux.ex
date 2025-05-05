defmodule Timesink.Storage.Mux do
  @moduledoc """
  Mux-centric storage functions.
  """

  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.MuxUpload

  @spec generate_upload_url(map(), keyword()) :: {:ok, map()} | {:error, any()}
  def generate_upload_url(upload_params, opts \\ []) do
    config = config()
    key_id = Keyword.get(opts, :access_key_id, config.access_key_id)
    key_secret = Keyword.get(opts, :access_key_secret, config.access_key_secret)

    mux_client = Mux.client(key_id, key_secret)

    Logger.debug("Calling Mux.Video.Uploads.create/2")
    Logger.debug("Mux client: #{inspect(mux_client)}")
    Logger.debug("Upload params: #{inspect(upload_params)}")

    case Mux.Video.Uploads.create(mux_client, upload_params) do
      {:ok, upload, _env} ->
        Logger.debug("Mux Upload Response: #{inspect(upload)}")
        {:ok, upload}

      {:error, reason, _env} ->
        Logger.error("Mux upload error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def create_mux_upload(upload_params) do
    mux_upload_params = %{
      upload_id: upload_params["upload_id"],
      url: upload_params["url"],
      meta: %{
        "film_id" => upload_params["film_id"]
      }
    }

    Repo.transaction(fn ->
      with {:ok, mux_upload} <- MuxUpload.create(mux_upload_params) do
        {:ok, mux_upload}
      else
        error ->
          error = if not match?({:error, _}, error), do: error, else: elem(error, 1)
          Logger.error(inspect(error))
          Repo.rollback(error)
      end
    end)
  end

  def delete_asset(asset_id, opts \\ []) do
    config = config()
    key_id = Keyword.get(opts, :access_key_id, config.access_key_id)
    key_secret = Keyword.get(opts, :access_key_secret, config.access_key_secret)

    mux_client = Mux.client(key_id, key_secret)

    with {:ok, "", _client} <- Mux.Video.Assets.delete(mux_client, asset_id) do
      {:ok, ""}
    else
      {:error, reason, _client} ->
        Logger.error("Error deleting Mux asset: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @type config :: %{
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @spec config() :: config
  def config do
    Application.get_env(:timesink, Timesink.Storage.Mux)
    |> Enum.into(%{})
  end
end
