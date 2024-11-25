defmodule Timesink.Cinema.Theater do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          name: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "theater" do
    field :name, :string

    has_one :exhibition, TimeSink.Exhibition

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params, _metadata) do
    changeset(struct, params)
  end

  @spec changeset(theater :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1)
  end
end
