defmodule Timesink.FilmCreative do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "film_creative" do
    belongs_to :film, Timesink.Film
    belongs_to :creative, Timesink.Creative

    field :role, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(creative :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:film, :creative, :role])
    |> validate_required([:role])
    |> cast_assoc(:film, required: true, with: &Timesink.Film.changeset/2)
    |> cast_assoc(:creative, required: true, with: &Timesink.Creative.changeset/2)
  end
end
