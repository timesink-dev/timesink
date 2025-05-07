defmodule Timesink.Cinema.Exhibition do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Cinema.Exhibition

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

  def upsert(%{"showcase_id" => showcase_id, "theater_id" => theater_id, "film_id" => film_id}) do
    with nil <-
           Timesink.Repo.get_by(Exhibition,
             showcase_id: showcase_id,
             theater_id: theater_id
           ) do
      create(%{
        showcase_id: showcase_id,
        theater_id: theater_id,
        film_id: film_id
      })
    else
      %Exhibition{} = existing ->
        existing
        |> Exhibition.update(%{
          film_id: film_id
        })
    end
  end
end
