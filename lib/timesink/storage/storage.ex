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
         blob_params <- %{id: blob_id, user_id: uid, uri: path, size: stats.size},
         {:ok, blob} <- Blob.create(blob_params) do
      {:ok, blob}
    end
  end

  @doc """
  Create a new attachment from a Blob or a Plug.Upload.

  ## Examples

      iex> Storage.create_attachment(%Plug.Upload{...}, %{assoc_id: profile.id, name: "avatar", table: "profile_attachment"})
      {:ok, %Storage.Attachment{...}}

      iex> Storage.create_attachment(%Blob{...}, %{assoc_id: profile.id, name: "avatar", table: "profile_attachment"})
      {:ok, %Storage.Attachment{...}}
  """
  @spec create_attachment(
          Ecto.Schema.t(),
          atom(),
          Plug.Upload.t() | Blob.t(),
          keyword()
        ) :: {:ok, Attachment.t()} | {:error, Ecto.Changeset.t() | term()}
  def create_attachment(struct, assoc_name, %Plug.Upload{} = upload, opts) do
    Repo.transaction(fn ->
      with {:ok, %Blob{} = blob} <- create_blob(upload, opts),
           {:ok, %Attachment{} = att} <- create_attachment(struct, assoc_name, blob, opts) do
        att
      else
        error ->
          error = if not match?({:error, _}, error), do: error, else: elem(error, 1)
          Repo.rollback(error)
      end
    end)
  end

  def create_attachment(struct, assoc_name, %Blob{} = blob, opts) do
    metadata = Keyword.get(opts, :metadata, %{})
    name = Keyword.get(opts, :name, Atom.to_string(assoc_name))

    struct
    |> Ecto.build_assoc(assoc_name, %{blob_id: blob.id, name: name, metadata: metadata})
    |> Repo.insert()
  end

  @spec config() :: config
  def config do
    Application.get_env(:timesink, Timesink.Storage.S3) |> Enum.into(%{})
  end
end
