defmodule Timesink.Repo.Migrations.CreateTableFilm do
  use Ecto.Migration

  def change do
    create table(:film, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :title, :string, null: false
      add :year, :integer, null: false
      add :duration, :integer
      add :color, :string
      add :aspect_ratio, :string
      add :format, :string
      add :synopsis, :text
    end

    create unique_index(:film, [:year, :title])

    create index(:film, [:inserted_at])
    create index(:film, [:title])
  end
end
