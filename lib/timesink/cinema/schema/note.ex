defmodule Timesink.Cinema.Note do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  alias Timesink.Account.User
  alias Timesink.Cinema.{Exhibition, Film}

  @type source :: :audience | :director
  @source [:audience, :director]
  def source, do: @source

  @type t :: %{
          __struct__: __MODULE__,
          source: source(),
          body: :string,
          offset_seconds: :number,
          status: :string,
          user: User.t(),
          exhibition: Exhibition.t() | nil,
          film: Film.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "note" do
    field :source, Ecto.Enum, values: @source, default: :audience
    field :body, :string
    field :offset_seconds, :integer
    field :status, Ecto.Enum, values: [:visible, :hidden, :flagged], default: :visible

    belongs_to :user, User
    belongs_to :exhibition, Exhibition
    belongs_to :film, Film

    timestamps(type: :utc_datetime)
  end

  @spec changeset(note :: t() | %__MODULE__{}, params :: map()) :: Ecto.Changeset.t()
  def changeset(note, params, _metadata \\ []) do
    note
    |> cast(params, [:source, :body, :offset_seconds, :status, :user_id, :exhibition_id, :film_id])
    |> validate_required([:source, :body, :offset_seconds, :status, :user_id])
    |> validate_length(:body, min: 3)
    |> validate_source_association()
  end

  defp validate_source_association(changeset) do
    source = get_field(changeset, :source)
    exhibition_id = get_field(changeset, :exhibition_id)
    film_id = get_field(changeset, :film_id)

    case source do
      :audience when is_nil(exhibition_id) ->
        add_error(changeset, :exhibition_id, "can't be blank")

      :director when is_nil(film_id) ->
        add_error(changeset, :film_id, "can't be blank")

      _ ->
        changeset
    end
  end
end
