defmodule Timesink.Cinema.CreativeClaim do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @statuses [:pending, :approved, :rejected]
  def statuses, do: @statuses

  @type t :: %{
          __struct__: __MODULE__,
          user_id: Ecto.UUID.t(),
          user: Timesink.Account.User.t(),
          creative_id: Ecto.UUID.t(),
          creative: Timesink.Cinema.Creative.t(),
          status: :pending | :approved | :rejected,
          message: String.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "creative_claim" do
    belongs_to :user, Timesink.Account.User
    belongs_to :creative, Timesink.Cinema.Creative

    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :message, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(claim, params, _metadata \\ []) do
    claim
    |> cast(params, [:user_id, :creative_id, :message])
    |> validate_required([:user_id, :creative_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:creative)
    |> unique_constraint([:user_id, :creative_id],
      message: "You have already submitted a claim for this creative."
    )
  end

  def status_changeset(claim, status) do
    claim
    |> cast(%{status: status}, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
  end
end
