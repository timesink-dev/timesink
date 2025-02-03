defmodule Timesink.Storage do
  @moduledoc """
  The Storage context.
  """

  # alias Timesink.Storage.Attachment
  alias Timesink.Storage.Blob
  alias ExAws.S3

  @type config :: %{
          host: String.t(),
          access_key_id: String.t(),
          access_key_secret: String.t(),
          bucket: String.t(),
          prefix: String.t()
        }

  @doc """
  Create a new blob from a Plug.Upload.

  ## Examples

      iex> Storage.create_blob(%Plug.Upload{...}, user_id: user.id)
      {:ok, %Storage.Blob{...}}
  """
  @spec create_blob(upload :: Plug.Upload.t(), opts :: Keyword.t()) ::
          {:ok, Blob.t()} | {:error, Ecto.Changeset.t() | term()}
  def create_blob(%Plug.Upload{} = upload, opts \\ []) do
    config = config()
    uid = Keyword.get(opts, :user_id)

    # The blob ID (UUID) is generated upront so we can attach it to S3 objects
    # before persisting blob info in the database
    blob_id = Ecto.UUID.generate()

    obj_path = "#{config.prefix}/#{upload.filename}"
    obj_meta = [blob_id: blob_id, uploaded_at: System.os_time(:millisecond)]

    with {:ok, stats} <- File.stat(upload.path),
         stream <- S3.Upload.stream_file(upload.path),
         op <- S3.upload(stream, config.bucket, obj_path, meta: obj_meta),
         {:ok, %{status_code: 200, body: %{key: path}}} <- ExAws.request(op),
         blob_params <- %{id: blob_id, user_id: uid, path: path, size: stats.size},
         {:ok, blob} <- Blob.create(blob_params) do
      {:ok, blob}
    end
  end

  @spec config() :: config
  def config do
    Application.get_env(:timesink, Timesink.Storage) |> Enum.into(%{})
  end
end
