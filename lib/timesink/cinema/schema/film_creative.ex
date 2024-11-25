defmodule Timesink.Cinema.FilmCreative do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type role :: :director | :producer | :writer | :cast | :crew
  @roles [:director, :producer, :writer, :cast, :crew]
  @spec roles() :: [:cast | :crew | :director | :producer | :writer, ...]
  def roles, do: @roles

  @type t :: %{
          __struct__: __MODULE__,
          film: Timesink.Film.t(),
          creative: Timesink.Creative.t(),
          role: role()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "film_creative" do
    belongs_to :film, Timesink.Cinema.Film
    belongs_to :creative, Timesink.Creative

    field :role, Ecto.Enum, values: @roles
    field :subrole, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(creative :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:film_id, :creative_id, :role])
    |> validate_required([:film_id, :creative_id, :role])
    |> assoc_constraint(:film)
    |> assoc_constraint(:creative)
  end
end
