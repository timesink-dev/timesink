defmodule Timesink.FilmShowing do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          film: Timesink.Film.t(),
          showcase: Timesink.Showcase.t(),
          theater: Timesink.Theater.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "film_showing" do
    belongs_to :film, Timesink.Film
    belongs_to :showcase, Timesink.Showcase
    belongs_to :theater, Timesink.Theater

    timestamps(type: :utc_datetime)
  end

  @spec changeset(film_showing :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:film, :showcase, :theater])
    |> validate_required([:film, :showcase, :theater])
    |> cast_assoc(:film, required: true, with: &Timesink.Film.changeset/2)
    |> cast_assoc(:showcase, required: true, with: &Timesink.Showcase.changeset/2)
    |> cast_assoc(:theater, required: true, with: &Timesink.Theater.changeset/2)
  end
end
