defmodule Timesink.Storage.Attachment do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type schema ::
          :creative
          | :exhibition
          | :film_creative
          | :film
          | :genre
          | :profile
          | :showcase
          | :theater
          | :user
  @schemas [
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
  def schemas, do: @schemas

  @type t :: %{
          __struct__: __MODULE__,
          blob_id: Ecto.UUID.t(),
          blob: Timesink.Storage.Blob.t(),
          schema: atom(),
          field_name: String.t(),
          field_id: Ecto.UUID.t(),
          metadata: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "attachment" do
    belongs_to :blob, Timesink.Storage.Blob

    field :schema, Ecto.Enum, values: @schemas
    field :field_name, :string
    field :field_id, :binary_id

    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @spec changeset(att :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = att, %{} = params) do
    att
    |> cast(params, [:blob_id, :schema, :field_name, :field_id, :metadata])
    |> validate_required([:blob_id, :schema, :field_name, :field_id])
    |> foreign_key_constraint(:blob_id)
    |> unique_constraint([:field_name, :field_id])
  end
end
