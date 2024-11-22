defmodule Timesink.Showcase do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type status :: :upcoming | :active | :archived
  @statuses [:upcoming, :active, :archived]
  def statuses, do: @statuses

  @type t :: %{
          __struct__: __MODULE__,
          name: :string,
          description: :string,
          start_date: :naive_datetime,
          end_date: :naive_datetime,
          status: status()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "showcase" do
    field :name, :string
    field :description, :string
    field :start_date, :naive_datetime
    field :end_date, :naive_datetime
    field :status, Ecto.Enum, values: @statuses, default: :upcoming

    has_many :exhibitions, TimeSink.Exhibition
    has_many :films, through: [:exhibitions, :film]

    timestamps(type: :utc_datetime)
  end

  @spec changeset(showcase :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:name, :description, :start_date, :end_date, :status])
    |> validate_required([:name, :description, :status])
    |> validate_length(:name, min: 1)
    |> validate_length(:description, min: 1)
    |> validate_inclusion(:status, @statuses)
  end
end
