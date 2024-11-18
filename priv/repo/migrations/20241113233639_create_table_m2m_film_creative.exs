defmodule Timesink.Repo.Migrations.CreateTableFilmCreative do
  use Ecto.Migration

  def change do
    create table(:film_creative, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :film_id, references(:films, type: :uuid), null: false
      add :creative_id, references(:films, type: :uuid), null: false

      add :role, :string, null: false
    end

    create unique_index(:film_creative, [:film_id, :creative_id, :role])

    create index(:film_creative, [:inserted_at])
    create index(:film_creative, [:creative_id, :film_id])
  end
end
