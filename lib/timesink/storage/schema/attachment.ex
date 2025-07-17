defmodule Timesink.Storage.Attachment do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          blob_id: Ecto.UUID.t(),
          blob: Timesink.Storage.Blob.t(),
          assoc_id: Ecto.UUID.t(),
          name: String.t(),
          metadata: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "abstract table: attachment" do
    field :assoc_id, :binary_id
    field :name, :string
    belongs_to :blob, Timesink.Storage.Blob

    timestamps(type: :utc_datetime)
  end

  def changeset(%{__struct__: __MODULE__} = att, %{} = params) do
    att
    |> cast(params, [:blob_id, :assoc_id, :name])
    |> validate_required([:blob_id, :assoc_id, :name])
    |> foreign_key_constraint(:blob_id)
    |> unique_constraint([:assoc_id, :name])
  end
end
