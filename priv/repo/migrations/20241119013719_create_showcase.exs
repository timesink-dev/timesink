defmodule Timesink.Repo.Migrations.CreateShowcase do
  use Ecto.Migration

  def change do
    create table(:showcase, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :title, :string, null: false
      add :description, :text
      add :status, :showcase_status, null: false, default: "upcoming"
      add :start_at, :utc_datetime
      add :end_at, :utc_datetime
    end

    create unique_index(:showcase, [:status], where: "status = 'active'")
  end
end
