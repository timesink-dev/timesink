defmodule Timesink.Cinema.Creative do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          first_name: :string,
          last_name: :string,
          profile: Timesink.Accounts.Profile.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "creative" do
    belongs_to :profile, Timesink.Accounts.Profile

    field :first_name, :string
    field :last_name, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(creative :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(creative, params, _metadata \\ []) do
    creative
    |> cast(params, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 2)
    |> validate_length(:last_name, min: 2)
  end

  def full_name(%{first_name: f, last_name: l}), do: "#{f} #{l}"
end
