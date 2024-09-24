defmodule Timesink.Accounts.InviteCode do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  import Ecto.Changeset

  @type t :: %{
          __struct__: __MODULE__,
          code: String.t(),
          is_used: boolean(),
          is_sent: boolean(),
          issuer_id: Ecto.UUID.t()
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "invite_codes" do
    # Redact sensitive invite code
    field :code, :string, redact: true
    # Indicates if the invite was redeemed
    field :is_used, :boolean, default: false
    # Indicates if the invite was sent
    field :is_sent, :boolean, default: false
    # The user who issued the invite (optional)
    belongs_to :issuer, Timesink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(invite_code :: t(), params :: %{optional(key :: atom()) => value :: term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct_: __MODULE__} = struct, params) do
    struct
    |> cast(params, [:code, :is_used, :is_sent, :issuer_id])
    |> validate_required([:code])
    |> unique_constraint(:code)
    # Ensure the invite code is 6 characters long (use crypto module to generate random alphanumeric strings)
    |> validate_length(:code, is: 6)
  end
end
