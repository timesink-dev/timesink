defmodule Timesink.Cinema.Showcase do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type status :: :upcoming | :active | :archived
  @statuses [:upcoming, :active, :archived]
  def statuses, do: @statuses

  @type t :: %{
          __struct__: __MODULE__,
          title: :string,
          description: :string,
          start_at: :naive_datetime,
          end_at: :naive_datetime,
          status: status()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "showcase" do
    field :title, :string
    field :description, :string
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime
    field :status, Ecto.Enum, values: @statuses, default: :upcoming

    has_many :exhibitions, Timesink.Cinema.Exhibition
    has_many :films, through: [:exhibitions, :film]

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params, _metadata) do
    changeset(struct, params)
  end

  @spec changeset(showcase :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:title, :description, :start_at, :end_at, :status])
    # |> validate_required([:title, :status])
    |> validate_length(:title, min: 1)
    |> validate_length(:description, min: 1)
    |> validate_inclusion(:status, @statuses)
  end
end
