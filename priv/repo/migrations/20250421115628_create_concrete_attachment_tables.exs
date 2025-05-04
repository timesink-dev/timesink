defmodule Timesink.Repo.Migrations.CreateConcreteAttachmentTables do
  use Ecto.Migration

  def change do
    for table <- ~w(profile film showcase)a do
      create table(:"#{table}_attachment", primary_key: false) do
        add :id, :uuid, primary_key: true
        add :assoc_id, references(:"#{table}", type: :uuid, on_delete: :delete_all), null: false
        add :blob_id, references(:blob, type: :uuid, on_delete: :delete_all), null: false
        add :name, :string, null: false
        timestamps(type: :utc_datetime)
      end

      create unique_index(:"#{table}_attachment", [:assoc_id, :name])
      create index(:"#{table}_attachment", [:blob_id])
    end
  end
end
