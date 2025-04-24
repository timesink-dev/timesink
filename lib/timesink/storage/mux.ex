defmodule Timesink.Storage.Mux do
  @moduledoc """
  Mux-centric storage functions.
  """

  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.MuxUpload

  # @spec generate_upload_url(
  #         params :: %{
  #           optional(:cors_origin) => String.t(),
  #           optional(:timeout) => integer(),
  #           optional(:test) => boolean(),
  #           optional(:new_asset_settings) => map()
  #         },
  #         opts :: Keyword.t()
  #       ) ::
  #         {:ok, map()} | {:error, term()}
  def generate_upload_url(upload_params, opts \\ []) do
    config = config()
    key_id = Keyword.get(opts, :access_key_id, config.access_key_id)
    key_secret = Keyword.get(opts, :access_key_secret, config.access_key_secret)

    mux_client = Mux.client(key_id, key_secret)
    IO.inspect(key_id, label: "Mux key_id")
    IO.inspect(key_secret, label: "Mux key_secret")
    IO.inspect(upload_params, label: "Mux upload params")

    params = %{
      "new_asset_settings" => %{"playback_policy" => ["public"], "video_quality" => "basic"},
      "cors_origin" => "http://127.0.0.1:4040 "
    }

    # case Mux.Video.Uploads.create(mux_client, params) do
    #   _ ->
    #     Logger.debug("Mux upload error")

    #   {:ok, data, _client} ->
    #     Logger.debug("Mux Upload Response: #{inspect(data)}")
    #     {:ok, data}

    #   {:error, reason, _client} ->
    #     Logger.error("Mux upload error: #{inspect(reason)}")
    #     {:error, reason}
    # end

    case Mux.Video.Uploads.create(mux_client, params) do
      {:ok, data, _client} ->
        IO.inspect(data, label: "Mux Upload Response")
        Logger.debug("Mux upload successful")
        {:ok, data}

      {:error, reason, _client} ->
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
        # "response" => upload_params
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
