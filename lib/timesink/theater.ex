defmodule Timesink.Theater do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          name: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "theater" do
    field :name, :string

    has_one :film_showing, TimeSink.FilmShowing

    timestamps(type: :utc_datetime)
  end

  @spec changeset(theater :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE} = struct, %{} = params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1)
    |> cast_assoc(:film_showing, with: &Timesink.FilmShowing.changeset/2)
    |> cast_assoc(:next_showing, with: &Timesink.FilmShowing.changeset/2)
  end
end
