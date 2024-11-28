defmodule Timesink.Cinema.Exhibition do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          film: Timesink.Cinema.Film.t(),
          showcase: Timesink.Cinema.Showcase.t(),
          theater: Timesink.Cinema.Theater.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "exhibition" do
    belongs_to :film, Timesink.Cinema.Film
    belongs_to :showcase, Timesink.Cinema.Showcase
    belongs_to :theater, Timesink.Cinema.Theater
    field :film_title, :string, virtual: true
    timestamps(type: :utc_datetime)
  end

  @spec changeset(exhibition :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(exhibition, params, _metadata \\ []) do
    exhibition
    |> cast(params, [:film_id, :showcase_id, :theater_id])
    |> validate_required([:film_id, :showcase_id, :theater_id])
    |> assoc_constraint(:film)
    |> assoc_constraint(:showcase)
    |> assoc_constraint(:theater)
  end
end
