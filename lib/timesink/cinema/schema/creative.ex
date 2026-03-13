defmodule Timesink.Cinema.Creative do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          first_name: :string,
          last_name: :string,
          full_name: :string,
          user: Timesink.Account.User.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "creative" do
    belongs_to :user, Timesink.Account.User

    field :first_name, :string
    field :last_name, :string
    field :full_name, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(creative, params, _metadata \\ []) do
    creative
    |> cast(params, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 2)
    |> validate_length(:last_name, min: 2)
    |> put_full_name()
  end

  def full_name(%{first_name: f, last_name: l}), do: "#{f} #{l}"

  def put_full_name(%Ecto.Changeset{} = changeset) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)

    put_change(
      changeset,
      :full_name,
      [first_name, last_name] |> Enum.reject(&is_nil/1) |> Enum.join(" ")
    )
  end

  def put_full_name(%__MODULE__{} = creative) do
    %{creative | full_name: full_name(creative)}
  end
end
