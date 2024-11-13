defmodule Timesink.Repo.Migrations.CreateTableFilms do
  use Ecto.Migration

  def change do
    create table(:films, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :title, :string, null: false
      add :year, :integer, null: false
      add :duration, :integer
      add :color, :string
      add :aspect_ratio, :string
      add :format, :integer
      add :synopsis, :string
    end

    create unique_index(:films, [:year, :title])

    create index(:films, [:inserted_at])
    create index(:films, [:title])
  end
end
