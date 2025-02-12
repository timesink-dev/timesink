defmodule Timesink.Repo.Migrations.CreateMuxUpload do
  use Ecto.Migration

  def change do
    create table(:mux_upload, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :status, :mux_upload_status, null: false, default: "waiting"
      add :upload_id, :string, null: false
      add :asset_id, :string
      add :playback_id, :string
      add :meta, :map
    end
  end
end
