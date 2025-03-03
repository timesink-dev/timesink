defmodule Timesink.Storage.Mux do
  @moduledoc """
  Mux-centric storage functions.
  """

  require Logger
  alias Timesink.Repo
  alias Timesink.Storage.MuxUpload

  @spec create_upload_url(
          params :: %{
            optional(:cors_origin) => String.t(),
            optional(:timeout) => integer(),
            optional(:test) => boolean(),
            optional(:new_asset_settings) => map()
          },
          opts :: Keyword.t()
        ) ::
          {:ok, MuxUpload.t()} | {:error, term()}
  def create_upload_url(upload_params \\ %{}, opts \\ []) do
    config = config()
    key_id = opts |> Keyword.get(:access_key_id, config.access_key_id)
    key_secret = opts |> Keyword.get(:access_key_secret, config.access_key_secret)

    Repo.transaction(fn ->
      mux_client = Mux.client(key_id, key_secret)

      with {:ok, resp, _} <- Mux.Video.Uploads.create(mux_client, upload_params),
           blob_params <- %{mux_id: resp["id"], meta: %{"response" => resp}},
           {:ok, mux_upload} <- MuxUpload.create(blob_params) do
        mux_upload
      else
        error ->
          error = if not match?({:error, _}, error), do: error, else: error |> elem(1)

          Logger.error(error |> inspect())
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
