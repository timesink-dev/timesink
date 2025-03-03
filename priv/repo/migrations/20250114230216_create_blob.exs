defmodule Timesink.Repo.Migrations.CreateBlob do
  use Ecto.Migration

  def change do
    create table(:blob, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :user_id, references(:user, type: :uuid, on_delete: :delete_all)
      add :service, :blob_service, null: false, default: "s3"
      add :uri, :string, null: false
      add :size, :integer
      add :mime, :string
      add :checksum, :string
      add :metadata, :map
    end

    create unique_index(:blob, [:uri])

    create index(:blob, [:size])
    create index(:blob, [:mime])
    create index(:blob, [:checksum])
  end
end
