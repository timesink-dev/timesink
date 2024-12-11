defmodule Timesink.Cinema.Theater do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          name: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "theater" do
    field :name, :string
    field :description, :string
    has_one :exhibition, TimeSink.Cinema.Exhibition

    timestamps(type: :utc_datetime)
  end

  @spec changeset(theater :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(theater, params, _metadata \\ []) do
    theater
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1)
  end
end
