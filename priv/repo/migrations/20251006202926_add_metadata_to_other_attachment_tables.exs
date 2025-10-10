defmodule Timesink.Repo.Migrations.AddMetadataToOtherAttachmentTables do
  defmodule Timesink.Repo.Migrations.AddMetadataToFilmAndShowcaseAttachments do
    use Ecto.Migration

    def change do
      alter table(:film_attachment) do
        add :metadata, :map, null: true, default: nil
      end
    end
  end
end
