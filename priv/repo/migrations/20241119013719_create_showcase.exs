defmodule Timesink.Repo.Migrations.CreateShowcase do
  use Ecto.Migration

  def change do
    create table(:showcase, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :is_active, :boolean, null: false, default: true
      add :title, :string, null: false
    end

    create unique_index(:showcase, [:is_active])

    create index(:showcase, [:inserted_at])
    create index(:showcase, [:is_active, :title])
  end
end
