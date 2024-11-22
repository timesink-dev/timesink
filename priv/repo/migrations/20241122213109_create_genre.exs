defmodule Timesink.Repo.Migrations.CreateGenre do
  use Ecto.Migration

  def change do
    create table(:genre, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :name, :string, null: false
      add :description, :string
    end

    create unique_index(:genre, [:name])

    create index(:creative, [:inserted_at])

    create table(:film_genre, primary_key: false) do
      add :film_id, references(:film, type: :uuid, on_delete: :delete_all), primary_key: true
      add :genre_id, references(:genre, type: :uuid, on_delete: :delete_all), primary_key: true
    end
  end
end
