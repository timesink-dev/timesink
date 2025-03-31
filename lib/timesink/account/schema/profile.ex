defmodule Timesink.Accounts.Profile do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Accounts

  @type t :: %{
          __struct__: __MODULE__,
          user_id: Ecto.UUID.t(),
          user: Accounts.User.t(),
          avatar_url: String.t(),
          birthdate: Date.t(),
          location: Accounts.Location.t(),
          org_name: String.t(),
          org_position: String.t(),
          bio: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "profile" do
    belongs_to :user, Accounts.User

    field :avatar_url, :string
    field :birthdate, :date
    field :org_name, :string
    field :org_position, :string
    field :bio, :string

    embeds_one :location, Accounts.Location

    has_one :creative, Timesink.Creative

    timestamps(type: :utc_datetime)
  end

  @spec changeset(profile :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [
      :user_id,
      :avatar_url,
      :birthdate,
      :org_name,
      :org_position,
      :bio
    ])
    |> cast_embed(:location, required: false)
    |> cast_assoc(:user, with: &Accounts.User.changeset/2)
  end

  def birthdate_changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:birthdate])
    |> validate_birthdate()
  end

  defp validate_birthdate(changeset) do
    validate_change(changeset, :birthdate, fn :birthdate, date ->
      cond do
        is_nil(date) ->
          [birthdate: "Birthdate is required"]

        Date.compare(date, Date.utc_today()) == :gt ->
          [birthdate: "You can’t be born in the future — unless you're in a sci-fi film."]

        date.year < 1900 ->
          [birthdate: "That seems a bit early. We’re flattered, though."]

        true ->
          []
      end
    end)
  end
end
