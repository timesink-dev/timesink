defmodule Timesink.File do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Waffle.Ecto.Schema
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          user_id: :integer,
          name: :string,
          size: :integer,
          content_type: :string,
          content_hash: :string,
          content: :string,
          user: Timesink.Accounts.User.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "file" do
    belongs_to :user, Timesink.Accounts.User

    field :name, :string
    field :size, :integer
    field :content_type, :string
    field :content_hash, :string
    field :content, Timesink.FileWaffle.Type

    timestamps(type: :utc_datetime)
  end

  @spec changeset(file :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(file, params) do
    file
    |> cast(params, [:name, :size])
    |> cast_assoc(:user, with: &Timesink.Accounts.User.changeset/2)
    |> cast_attachments(params, [:content])
    |> validate_required([:name, :size, :content])
    |> unique_constraint(:name)
  end

  @doc """
  Hashes a binary into a lower-cased MD5.

  ## Examples

      iex> "José Valim" |> File.hash()
      "51e2b1c9fac3770b4aa432b7297551d6"
  """
  @spec hash(binary()) ::
          binary()
  def hash(content) when is_binary(content) do
    content
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode16(case: :lower)
  end
end
