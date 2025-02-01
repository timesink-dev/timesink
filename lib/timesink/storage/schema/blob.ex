defmodule Timesink.Storage.Blob do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          user_id: :integer,
          user: Timesink.Accounts.User.t(),
          path: :string,
          size: :integer,
          mime: :string,
          checksum: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "blob" do
    belongs_to :user, Timesink.Accounts.User

    field :path, :string
    field :size, :integer
    field :mime, :string
    field :checksum, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(blob :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = blob, %{} = params) do
    blob
    |> cast(params, [:id, :user_id, :path, :size, :mime, :checksum])
    |> validate_required([:path, :size])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:path)
  end

  @doc """
  The path prefix (base dir) for blob storage.

  ## Examples

      iex> Blob.prefix()
      "blobs"
  """
  @spec prefix() ::
          String.t()
  def prefix do
    Application.fetch_env!(:timesink, Timesink.Storage)
    |> Keyword.fetch!(:prefix)
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

  def size(%Plug.Upload{} = upload), do: File.stat!(upload.path) |> Map.get(:size)
end
