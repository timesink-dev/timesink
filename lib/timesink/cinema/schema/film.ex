defmodule Timesink.Cinema.Film do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type color ::
          :color | :black_and_white | :sepia | :monochrome | :partially_colorized | :techinicolor
  @colors [:color, :black_and_white, :sepia, :monochrome, :partially_colorized, :technicolor]
  def colors, do: @colors

  @type format :: :digital | :"70mm" | :"65mm" | :"35mm" | :"16mm" | :"8mm"
  @formats [:digital, :"70mm", :"65mm", :"35mm", :"Super 16mm", :"16mm", :"8mm"]
  def formats, do: @formats

  @type t :: %{
          __struct__: __MODULE__,
          title: :string,
          year: :integer,
          duration: :integer,
          color: color(),
          aspect_ratio: :string,
          format: format(),
          synopsis: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "film" do
    field :title, :string
    field :year, :integer
    # Duration in minutes
    field :duration, :integer
    field :color, Ecto.Enum, values: @colors
    field :aspect_ratio, :string
    field :format, Ecto.Enum, values: @formats
    field :synopsis, :string

    has_one :video, {"film_attachment", Timesink.Storage.Attachment},
      foreign_key: :assoc_id,
      where: [name: "video"]

    has_one :poster, {"film_attachment", Timesink.Storage.Attachment},
      foreign_key: :assoc_id,
      where: [name: "poster"]

    has_one :trailer, {"film_attachment", Timesink.Storage.Attachment},
      foreign_key: :assoc_id,
      where: [name: "trailer"]

    many_to_many :genres, Timesink.Cinema.Genre, join_through: "film_genre"

    has_many :directors, Timesink.Cinema.FilmCreative, where: [role: :director]
    has_many :producers, Timesink.Cinema.FilmCreative, where: [role: :producer]
    has_many :writers, Timesink.Cinema.FilmCreative, where: [role: :writer]
    has_many :cast, Timesink.Cinema.FilmCreative, where: [role: :cast]
    has_many :crew, Timesink.Cinema.FilmCreative, where: [role: :crew]

    timestamps(type: :utc_datetime)
  end

  @spec changeset(film :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(film, params, _metadata \\ []) do
    film
    |> cast(params, [:title, :year, :duration, :color, :aspect_ratio, :format, :synopsis])
    |> validate_required([:title, :year, :duration, :color, :aspect_ratio, :format, :synopsis])
    |> validate_length(:title, min: 1)
  end

  def attach_poster(%{__struct__: __MODULE__} = film, upload) do
    Timesink.Storage.create_attachment(film, :poster, upload)
  end

  def attach_video(%{__struct__: __MODULE__} = film, upload) do
    IO.inspect(upload, label: "attach_video")
    Timesink.Storage.create_attachment(film, :video, upload)
  end

  def attach_trailer(%{__struct__: __MODULE__} = film, upload) do
    Timesink.Storage.create_attachment(film, :trailer, upload)
  end
end
