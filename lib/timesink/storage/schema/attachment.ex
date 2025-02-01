defmodule Timesink.Storage.Attachment do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type assoc_schema ::
          :creative
          | :exhibition
          | :film_creative
          | :film
          | :genre
          | :profile
          | :showcase
          | :theater
          | :user
  @assoc_schemas [
    :creative,
    :exhibition,
    :film_creative,
    :film,
    :genre,
    :profile,
    :showcase,
    :theater,
    :user
  ]
  def assoc_schemas, do: @assoc_schemas

  @type t :: %{
          __struct__: __MODULE__,
          blob_id: Ecto.UUID.t(),
          blob: Timesink.Storage.Blob.t(),
          assoc_schema: atom(),
          assoc_id: integer(),
          metadata: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "attachment" do
    belongs_to :blob, Timesink.Storage.Blob

    field :assoc_schema, Ecto.Enum, values: @assoc_schemas
    field :assoc_id, :binary_id

    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @spec changeset(att :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = att, %{} = params) do
    att
    |> cast(params, [:blob_id, :assoc_schema, :assoc_id, :metadata])
    |> validate_required([:blob_id, :assoc_schema, :assoc_id])
    |> foreign_key_constraint(:blob_id)
  end
end
