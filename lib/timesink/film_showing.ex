defmodule Timesink.FilmShowing do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          film: Timesink.Film.t(),
          showcase: Timesink.Showcase.t(),
          theater: Timesink.Theater.t(),
          upcoming_showing: Timesink.FilmShowing.t()
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
    |> cast(params, [:film, :showcase, :theater, :upcoming_showing])
    |> validate_required([:film, :showcase, :theater])
    |> cast_assoc(:film, with: &Timesink.Film.changeset/2)
    |> cast_assoc(:showcase, with: &Timesink.Showcase.changeset/2)
    |> cast_assoc(:theater, with: &Timesink.Theater.changeset/2)
    |> cast_assoc(:upcoming_showing, with: &Timesink.FilmShowing.changeset/2)
  end
end
