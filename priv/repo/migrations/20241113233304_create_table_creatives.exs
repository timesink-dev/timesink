defmodule Timesink.Repo.Migrations.CreateTableCreatives do
  use Ecto.Migration

  def change do
    create table(:creatives, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :user_id, references(:users, type: :uuid), null: false

      add :first_name, :string, null: false
      add :last_name, :string, null: false
    end

    create unique_index(:creatives, [:last_name, :first_name])

    create index(:creatives, [:inserted_at])
    create index(:creatives, [:first_name, :last_name])
  end
end
