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
  Creates a new attachment for a given schema record and association.

  This function supports either a `%Plug.Upload{}` (which will create a new blob)
  or a pre-existing `%Blob{}`.

  The associated schema must declare a `has_one` or `has_many` relationship
  with a properly scoped `where: [name: ...]` clause in order to work with `build_assoc/3`.

  ## Examples

  Attach an avatar upload to a profile:

      iex> Storage.create_attachment(profile, :avatar, %Plug.Upload{...})
      {:ok, %Storage.Attachment{}}

  Attach a trailer upload to a film, with metadata:

      iex> Storage.create_attachment(film, :trailer, %Plug.Upload{...}, metadata: %{duration: "2m34s"})
      {:ok, %Storage.Attachment{}}

  Attach an existing blob as a poster:

      iex> Storage.create_attachment(film, :poster, %Blob{id: "..."})
      {:ok, %Storage.Attachment{}}

  You can optionally override the attachment `name` (defaults to the association name):

      iex> Storage.create_attachment(profile, :documents, upload, name: "insurance_card")
  """
  @spec create_attachment(
          Ecto.Schema.t(),
          atom(),
          Plug.Upload.t() | Blob.t()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t() | term()}

  @spec create_attachment(
          Ecto.Schema.t(),
          atom(),
          Plug.Upload.t() | Blob.t(),
          keyword()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t() | term()}

  def create_attachment(struct, assoc_name, upload_or_blob) do
    create_attachment(struct, assoc_name, upload_or_blob, [])
  end

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
