defmodule Timesink.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      timestamps type: :utc_datetime

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :sex, :string
      add :birthdate, :date
      add :location, :map
      add :org_name, :string
      add :org_position, :string
      add :bio, :string
    end

    create unique_index(:profiles, [:user_id])

    create index(:profiles, [:inserted_at])
  end
end
