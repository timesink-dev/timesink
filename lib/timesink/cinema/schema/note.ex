defmodule Timesink.Cinema.Note do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  alias Timesink.Account.User
  alias Timesink.Cinema.Exhibition

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
          exhibition: Exhibition.t()
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

    timestamps(type: :utc_datetime)
  end

  @spec changeset(note :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(note, params, _metadata \\ []) do
    note
    |> cast(params, [:source, :body, :offset_seconds, :status, :user_id, :exhibition_id])
    |> validate_required([:source, :body, :offset_seconds, :status, :user_id, :exhibition_id])
    |> validate_length(:body, min: 3)
  end
end
