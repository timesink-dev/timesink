defmodule Timesink.Repo.Migrations.CreateCinemaNote do
  use Ecto.Migration

  def change do
    create table(:note, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      add :source, :string, null: false, default: "audience"
      add :body, :text, null: false
      add :offset_seconds, :integer, null: false

      add :status, :string, null: false, default: "visible"

      add :user_id, references(:user, type: :uuid), null: false
      add :exhibition_id, references(:exhibition, type: :uuid), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:note, [:exhibition_id, :offset_seconds])
  end
end
