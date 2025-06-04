defmodule Timesink.Cinema.Theater do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Utils

  @type t :: %{
          __struct__: __MODULE__,
          name: :string,
          slug: :string,
          playback_interval_minutes: :integer,
          description: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "theater" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :playback_interval_minutes, :integer, default: 15
    has_one :exhibition, Timesink.Cinema.Exhibition

    timestamps(type: :utc_datetime)
  end

  @spec changeset(theater :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(theater, params, _metadata \\ []) do
    theater
    |> cast(params, [:name, :description, :slug, :playback_interval_minutes])
    |> validate_required([:name, :slug, :playback_interval_minutes])
    |> validate_length(:name, min: 1)
    |> put_slug()
  end

  defp put_slug(changeset) do
    if name = get_change(changeset, :name) do
      slug = Utils.slugify(name)
      IO.inspect(slug, label: "Generated slug")
      put_change(changeset, :slug, slug)
    else
      changeset
    end
  end
end
