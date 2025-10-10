defmodule Timesink.Repo.Migrations.AddMetadataToOtherAttachmentTables do
  use Ecto.Migration

  def change do
    alter table(:film_attachment) do
      add :metadata, :map, null: true, default: nil
    end

    alter table(:showcase_attachment) do
      add :metadata, :map, null: true, default: nil
    end

    alter table(:profile_attachment) do
      add :metadata, :map, null: true, default: nil
    end
  end
end
