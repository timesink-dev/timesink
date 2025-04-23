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
            optional(:new_asset_settings) => map(),
            optional(:film_id) => Ecto.UUID.t() | String.t()
          },
          opts :: Keyword.t()
        ) ::
          {:ok, MuxUpload.t()} | {:error, term()}
  def create_upload_url(upload_params, opts \\ []) do
    config = config()
    key_id = Keyword.get(opts, :access_key_id, config.access_key_id)
    key_secret = Keyword.get(opts, :access_key_secret, config.access_key_secret)

    # Extract and remove `film_id` from the upload_params, so it doesn't go to Mux
    {film_id, upload_params} = Map.pop(upload_params, :film_id)

    Repo.transaction(fn ->
      mux_client = Mux.client(key_id, key_secret)

      with {:ok, resp, _} <- Mux.Video.Uploads.create(mux_client, upload_params),
           blob_params <- %{
             mux_id: resp["id"],
             meta: %{
               "film_id" => film_id,
               "response" => resp
             }
           },
           {:ok, mux_upload} <- MuxUpload.create(blob_params) do
        mux_upload
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
