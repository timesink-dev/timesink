defmodule Timesink.Accounts.Profile do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Accounts
  alias Timesink.Storage

  @type t :: %{
          __struct__: __MODULE__,
          user_id: Ecto.UUID.t(),
          user: Accounts.User.t(),
          avatar: Timesink.Storage.Attachment.t(),
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

    has_one :avatar, {"profile_attachment", Storage.Attachment},
      foreign_key: :assoc_id,
      where: [name: "avatar"]

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
    |> validate_required([:birthdate])
    |> validate_date()
  end

    def attach_avatar(%{__struct__: __MODULE__} = profile, %Plug.Upload{} = upload) do
    Storage.create_attachment(profile, :avatar, upload)
  end

  defp validate_date(changeset) do
    validate_change(changeset, :birthdate, fn :birthdate, date ->
      cond do
        Date.compare(date, Date.utc_today()) == :gt ->
          [birthdate: "You can’t be born in the future McFly!"]

        too_old_to_believe?(date) ->
          [birthdate: "That seems a bit early. We’re flattered, though."]

        too_young?(date) ->
          [birthdate: "Sorry! You'll have to wait a few years to be able to join the platform."]

        true ->
          []
      end
    end)
  end

  defp too_young?(date) do
    Date.diff(Date.utc_today(), date) < 16 * 365
  end

  defp too_old_to_believe?(date) do
    Date.diff(Date.utc_today(), date) > 110 * 365
end
end
