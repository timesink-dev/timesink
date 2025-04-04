defmodule Timesink.Repo.Migrations.CreateFilmTheater do
  use Ecto.Migration

  def change do
    create table(:theater, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :is_active, :boolean, null: false, default: true
      add :name, :string, null: false
      add :description, :text
    end

    create index(:theater, [:inserted_at])
    create index(:theater, [:is_active, :name])
  end
end
