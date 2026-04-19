defmodule Timesink.Repo.Migrations.AddFilmIdToNote do
  use Ecto.Migration

  def change do
    alter table(:note) do
      add :film_id, references(:film, type: :uuid), null: true
      modify :exhibition_id, :uuid, null: true
    end

    create index(:note, [:film_id, :offset_seconds])

    create constraint(:note, :requires_exhibition_or_film,
             check: "(exhibition_id IS NOT NULL OR film_id IS NOT NULL)"
           )
  end
end
