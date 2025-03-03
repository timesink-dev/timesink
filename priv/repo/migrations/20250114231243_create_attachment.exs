defmodule Timesink.Repo.Migrations.CreateAttachment do
  use Ecto.Migration

  def change do
    create table(:attachment, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      # Eg.: "picture", "file", "ticket_pdf", etc.
      add :name, :string, null: false

      add :blob_id, references(:blob, type: :uuid), null: false

      add :target_schema, :attachment_schema, null: false
      add :target_id, :uuid, null: false

      add :metadata, :map
    end

    create unique_index(:attachment, [:target_schema, :target_id, :name])

    create index(:attachment, [:blob_id])
    create index(:attachment, [:target_schema, :name, :target_id])
  end
end
