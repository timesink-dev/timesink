defmodule Timesink.Storage.Blob do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Storage

  @type service :: :s3 | :mux

  @type t :: %{
          __struct__: __MODULE__,
          service: service(),
          uri: :string,
          url: :string,
          size: :integer,
          mime: :string,
          checksum: :string,
          metadata: :map
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "blob" do
    has_one :attachment, {"blob_attachment", Storage.Attachment}, foreign_key: :assoc_id
    field :service, Ecto.Enum, values: [:s3, :mux], default: :s3
    field :uri, :string
    field :size, :integer
    field :mime, :string
    field :checksum, :string
    field :metadata, :map
    field :mux_playback_id, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(blob :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = blob, %{} = params) do
    blob
    |> cast(params, [:id, :uri, :size, :mime, :checksum, :metadata, :service])
    |> validate_required([:uri])
    |> validate_change(:metadata, fn _, value ->
      if is_map(value), do: [], else: [metadata: "must be a map"]
    end)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:uri)
  end

  @doc """
  Checksums a binary into a lower-cased MD5.

  ## Examples

      iex> "José Valim" |> Blob.checksum()
      "51e2b1c9fac3770b4aa432b7297551d6"
  """
  @spec checksum(binary()) ::
          binary()
  def checksum(content) when is_binary(content) do
    content
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode16(case: :lower)
  end

  @doc """
  Calculate a blob content byte size.

  ## Examples

      iex> "José Valim" |> Blob.size()
      11
  """
  @spec size(binary() | %Plug.Upload{}) ::
          non_neg_integer()
  def size(binary) when is_binary(binary), do: :erlang.byte_size(binary)

  def size(%Plug.Upload{} = upload), do: File.stat!(upload.path).size
end
