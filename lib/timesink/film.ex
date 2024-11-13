defmodule Timesink.Film do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type color :: :black_and_white | :sepia | :monochrome | :partially_colorized | :color
  @colors [:black_and_white, :sepia, :monochrome, :partially_colorized, :color]

  @type t :: %{
          __struct__: __MODULE__,
          title: :string,
          year: :integer,
          duration: :integer,
          color: color(),
          aspect_ratio: :string,
          format: :integer,
          synopsis: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "films" do
    field :title, :string
    field :year, :integer
    field :duration, :integer
    field :color, Ecto.Enum, values: @colors
    field :aspect_ratio, :string
    field :format, :integer
    field :synopsis, :string

    has_many :directors, Timesink.FilmCreative
    has_many :producers, Timesink.FilmCreative
    has_many :writers, Timesink.FilmCreative
    has_many :cast, Timesink.FilmCreative
    has_many :crew, Timesink.FilmCreative

    timestamps(type: :utc_datetime)
  end

  @spec changeset(film :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:title, :year, :duration, :color, :aspect_ratio, :format, :synopsis])
    |> validate_required([:title, :year, :synopsis])
    |> validate_length(:title, min: 1)
  end
end
