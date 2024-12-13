defmodule Timesink.Waitlist.Applicant do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type status :: :pending | :invited | :completed
  @statuses [:pending, :invited, :completed]
  def statuses, do: @statuses

  @type t :: %{
          __struct__: __MODULE__,
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          status: status()
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "waitlist" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :status, Ecto.Enum, values: @statuses, default: :pending

    timestamps(type: :utc_datetime)
  end

  @spec changeset(applicant :: %__MODULE__{}, params :: %{optional(key :: atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, params \\ %{}, _metadata \\ []) do
    struct
    |> cast(params, [:email, :status, :first_name, :last_name])
    |> validate_required([:email, :first_name, :last_name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email, message: "Email already exists")
  end
end
