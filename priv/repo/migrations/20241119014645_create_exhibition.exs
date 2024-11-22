defmodule Timesink.Repo.Migrations.CreateExhibition do
  use Ecto.Migration

  def change do
    create table(:exhibition, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :showcase_id, references(:showcase, type: :uuid), null: false
      add :theater_id, references(:theater, type: :uuid), null: false
      add :film_id, references(:film, type: :uuid), null: false
    end

    create unique_index(:exhibition, [:showcase_id, :theater_id])

    create index(:exhibition, [:inserted_at])
    create index(:exhibition, [:film_id])
  end
end
