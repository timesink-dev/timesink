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
  def create_blob(%Plug.Upload{} = upload, opts \\ []) do
    config = config()
    uid = Keyword.get(opts, :user_id)

    # Make S3 key unique to avoid collisions
    blob_id = Ecto.UUID.generate()
    obj_path = Path.join([config.prefix, blob_id, upload.filename])

    # ExAws will prefix these as x-amz-meta-...
    obj_meta = [blob_id: blob_id, uploaded_at: System.os_time(:millisecond)]

    case File.stat(upload.path) do
      {:ok, stats} ->
        stream = S3.Upload.stream_file(upload.path)
        op = S3.upload(stream, config.bucket, obj_path, meta: obj_meta)

        case ExAws.request(op) do
          {:ok, %{status_code: sc}} when sc in 200..299 ->
            blob_params = %{
              id: blob_id,
              user_id: uid,
              # <— we KNOW the key we wrote
              uri: obj_path,
              size: stats.size,
              mime: upload.content_type,
              checksum: Timesink.Storage.Blob.checksum(upload.path)
            }

            case Timesink.Storage.Blob.create(blob_params) do
              {:ok, blob} ->
                {:ok, blob}

              {:error, cs_or_reason} ->
                require Logger
                Logger.error("Blob DB insert failed: #{inspect(cs_or_reason)}")
                {:error, cs_or_reason}
            end

          {:ok, bad} ->
            require Logger
            Logger.error("S3 upload unexpected response: #{inspect(bad)}")
            {:error, {:s3_unexpected_response, bad}}

          {:error, reason} ->
            require Logger
            Logger.error("S3 upload failed: #{inspect(reason)}")
            {:error, {:s3_upload_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:stat_failed, reason}}
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

  @doc """
  Deletes an attachment and its associated blob from S3 and the database.
  """
  @spec delete_attachment(Attachment.t()) ::
          {:ok, :deleted} | {:error, term()}
  def delete_attachment(%Attachment{} = attachment) do
    Repo.transaction(fn ->
      # Load associated blob
      blob = Repo.preload(attachment, :blob).blob

      # Delete file from S3
      with {:ok, _} <- Timesink.Storage.S3.delete(blob.uri),
           {:ok, _} <- Attachment.delete(attachment),
           {:ok, _} <- Blob.delete(blob) do
        :deleted
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @spec config() :: config
  def config do
    Application.get_env(:timesink, Timesink.Storage.S3) |> Enum.into(%{})
  end
end
