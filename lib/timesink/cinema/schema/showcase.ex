defmodule Timesink.Cinema.Showcase do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  import Ecto.Query

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

  @spec changeset(showcase :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(showcase, params, _metadata \\ []) do
    showcase
    |> cast(params, [:title, :description, :start_at, :end_at, :status])
    |> validate_required([:title, :status])
    |> validate_length(:title, min: 1)
    |> validate_length(:description, min: 1)
    |> validate_inclusion(:status, @statuses)
  end

  def list_archived_showcases do
    Repo.all(
      from s in Timesink.Cinema.Showcase,
        where: s.status == :archived,
        preload: [
          exhibitions: [
            :theater,
            film: [
              {:poster, [:blob]},
              # {:video, [:blob]}, # optional if not needed in archives
              :genres,
              directors: [:creative],
              writers: [:creative],
              producers: [:creative],
              cast: [:creative],
              crew: [:creative]
            ]
          ]
        ]
    )
    |> Enum.map(fn showcase ->
      sorted_exhibitions =
        Enum.sort_by(showcase.exhibitions, fn ex ->
          String.downcase(ex.theater.name)
        end)

      %{showcase | exhibitions: sorted_exhibitions}
    end)
    |> Enum.sort_by(fn s -> s.start_at || s.inserted_at end, {:desc, Date})
  end

  def list_upcoming_showcases do
    Repo.all(
      from s in Timesink.Cinema.Showcase,
        where: s.status == :upcoming,
        preload: [
          exhibitions: [
            :theater,
            film: [
              {:poster, [:blob]},
              :genres,
              directors: [:creative],
              writers: [:creative],
              producers: [:creative],
              cast: [:creative],
              crew: [:creative]
            ]
          ]
        ]
    )
    |> Enum.map(fn showcase ->
      sorted_exhibitions =
        Enum.sort_by(showcase.exhibitions, fn ex ->
          String.downcase(ex.theater.name)
        end)

      %{showcase | exhibitions: sorted_exhibitions}
    end)
    |> Enum.sort_by(fn s -> s.start_at || s.inserted_at end, {:desc, Date})
  end
end
