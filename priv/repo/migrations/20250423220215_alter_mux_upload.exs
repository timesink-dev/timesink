defmodule Timesink.Repo.Migrations.AlterMuxUpload do
  use Ecto.Migration

  def change do
    alter table(:mux_upload) do
      remove :mux_id
      remove :asset_id
      remove :playback_id

      add :upload_id, :string, null: false
      add :url, :text, null: false
    end

    create unique_index(:mux_upload, [:upload_id])
  end
end
