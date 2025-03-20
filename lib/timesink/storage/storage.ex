defmodule Timesink.Storage do
  @moduledoc """
  The Storage context.
  """

  alias ExAws.S3
  alias Timesink.Repo
  alias Timesink.Storage.Attachment
  alias Timesink.Storage.Blob

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

  @doc """
  Create a new attachment from a Blob or a Plug.Upload.

  ## Examples

      iex> Storage.create_attachment(%Plug.Upload{...}, %{target_schema: :profile, target_id, profile.id, name: "picture"}, user_id: user.id)
      {:ok, %Storage.Attachment{...}}

      iex> Storage.create_attachment(%Blob{...}, %{target_schema: :profile, target_id, profile.id, name: "picture"}, user_id: user.id)
      {:ok, %Storage.Attachment{...}}
  """
  @spec create_attachment(
          upload_or_blob :: Plug.Upload.t() | Blob.t(),
          params :: %{
            :target_schema => String.t(),
            :target_id => Ecto.UUID.t(),
            :name => String.t(),
            optional(:metadata) => map()
          },
          opts :: Keyword.t()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t() | term()}
  def create_attachment(upload_or_blob, params, opts \\ [])

  def create_attachment(
        %Plug.Upload{} = upload,
        %{target_schema: _, target_id: _, name: _} = params,
        opts
      ) do
    Repo.transaction(fn ->
      with {:ok, %Blob{} = blob} <- create_blob(upload, opts),
           {:ok, %Attachment{} = att} <- create_attachment(blob, params, opts) do
        att
      else
        error ->
          error = if not match?({:error, _}, error), do: error, else: error |> elem(1)
          Repo.rollback(error)
      end
    end)
  end

  def create_attachment(
        %Blob{} = blob,
        %{target_schema: _, target_id: _, name: _} = params,
        _opts
      ) do
    params |> Map.put(:blob_id, blob.id) |> Attachment.create()
  end

  @spec config() :: config
  def config do
    Application.get_env(:timesink, Timesink.Storage) |> Enum.into(%{})
  end
end
