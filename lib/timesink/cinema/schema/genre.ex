defmodule Timesink.Cinema.Genre do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          name: :string,
          description: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "genre" do
    field :name, :string
    field :description, :string

    many_to_many :film, Timesink.Film, join_through: "film_genre"

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params, _metadata) do
    changeset(struct, params)
  end

  @spec changeset(genre :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1)
    |> unique_constraint([:name])
  end
end
