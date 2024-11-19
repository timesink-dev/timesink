defmodule Timesink.Repo.Migrations.CreateTableCreative do
  use Ecto.Migration

  def change do
    create table(:creative, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :user_id, references(:user, type: :uuid), null: false

      add :first_name, :string, null: false
      add :last_name, :string, null: false
    end

    create unique_index(:creative, [:last_name, :first_name])

    create index(:creative, [:inserted_at])
    create index(:creative, [:first_name, :last_name])
  end
end
