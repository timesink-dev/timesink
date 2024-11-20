defmodule Timesink.Repo.Migrations.CreateTableFilm do
  use Ecto.Migration

  def change do
    create table(:film, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :title, :string, null: false
      add :year, :integer, null: false
      add :duration, :integer, null: false
      add :color, :string, null: false
      add :aspect_ratio, :string, null: false
      add :format, :string, null: false
      add :synopsis, :text, null: false
    end

    create unique_index(:film, [:year, :title])

    create index(:film, [:inserted_at])
    create index(:film, [:title])

    create constraint(:film, :color_check,
             check:
               "color IN ('black_and_white', 'sepia', 'monochrome', 'partially_colorized', 'color')"
           )

    create constraint(:film, :format_check,
             check: "format IN ('digital', '70mm', '65mm', '35mm', '16mm', '8mm')"
           )
  end
end
