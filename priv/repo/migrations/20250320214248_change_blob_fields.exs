defmodule Timesink.Repo.Migrations.ChangeBlobFields do
  use Ecto.Migration

  def change do
    drop unique_index(:blob, [:path])

    rename table(:blob), :path, to: :uri

    alter table(:blob) do
      add :service, :blob_service, null: false, default: "s3"
      add :metadata, :map
    end

    create unique_index(:blob, [:uri])
  end
end
