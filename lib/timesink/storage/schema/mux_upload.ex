defmodule Timesink.Storage.MuxUpload do
  @moduledoc """
  Represents a Direct Upload from Mux.

  See: https://www.mux.com/docs/api-reference#video/tag/direct-uploads
  """

  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset

  @type status :: :waiting | :asset_created | :errored | :timed_out | :cancelled

  @type t :: %{
          __struct__: __MODULE__,
          status: status(),
          upload_id: :string,
          asset_id: :string,
          playback_id: :string
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mux_upload" do
    field :status, Ecto.Enum,
      values: [:waiting, :asset_created, :errored, :timed_out, :cancelled],
      default: :waiting

    field :upload_id, :string
    field :asset_id, :string
    field :playback_id, :string
    field :meta, :map

    timestamps(type: :utc_datetime)
  end

  @spec changeset(mux_upload :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{} = struct, %{} = params) do
    struct
    |> cast(params, [:status, :upload_id, :asset_id, :playback_id, :meta])
    |> validate_required([:status, :upload_id])
  end
end
