defmodule Timesink.Repo.Migrations.CreateAttachment do
  use Ecto.Migration

  def change do
    create table(:attachment, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :blob_id, references(:blob, type: :uuid, on_delete: :delete_all), null: false
      add :assoc_schema, :attachment_assoc_schema, null: false
      add :assoc_id, :integer, null: false

      add :metadata, :map, default: %{}
    end

    create index(:attachment, [:blob_id])
    create index(:attachment, [:assoc_schema, :assoc_id])
  end
end
