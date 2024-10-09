defmodule Timesink.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      timestamps type: :utc_datetime

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :birthdate, :date
      add :avatar_url, :string
      add :location, :map
      add :org_name, :string
      add :org_position, :string
      add :bio, :string
    end

    create unique_index(:profiles, [:user_id])

    create index(:profiles, [:inserted_at])
  end
end
