defmodule Timesink.Exhibition do
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

  schema "exhibition" do
    belongs_to :film, Timesink.Film
    belongs_to :showcase, Timesink.Showcase
    belongs_to :theater, Timesink.Theater

    timestamps(type: :utc_datetime)
  end

  @spec changeset(exhibition :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:film_id, :showcase_id, :theater_id])
    |> validate_required([:film_id, :showcase_id, :theater_id])
    |> assoc_constraint(:film)
    |> assoc_constraint(:showcase)
    |> assoc_constraint(:theater)
  end
end
