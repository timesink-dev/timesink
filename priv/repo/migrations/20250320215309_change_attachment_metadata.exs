defmodule Timesink.Repo.Migrations.ChangeAttachmentMetadata do
  use Ecto.Migration

  def change do
    alter table(:attachment) do
      modify :metadata, :map, null: true, default: nil, from: {:map, null: false, default: %{}}
    end
  end
end
