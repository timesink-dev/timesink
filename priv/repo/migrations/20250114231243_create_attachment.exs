defmodule Timesink.Repo.Migrations.CreateAttachment do
  use Ecto.Migration

  def change do
    create table(:attachment, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :blob_id, references(:blob, type: :uuid, on_delete: :delete_all), null: false
      add :schema, :attachment_assoc_schema, null: false
      add :field_name, :string, null: false
      add :field_id, :uuid, null: false

      add :metadata, :map, default: %{}
    end

    create unique_index(:attachment, [:field_name, :field_id])

    create index(:attachment, [:blob_id])
    create index(:attachment, [:schema, :field_name, :field_id])
  end
end
