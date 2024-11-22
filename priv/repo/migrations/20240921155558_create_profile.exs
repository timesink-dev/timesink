defmodule Timesink.Repo.Migrations.CreateProfile do
  use Ecto.Migration

  def change do
    create table(:profile, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      timestamps type: :utc_datetime

      add :user_id, references(:user, type: :uuid, on_delete: :delete_all), null: false
      add :birthdate, :date
      add :avatar_url, :string
      add :location, :map
      add :org_name, :string
      add :org_position, :string
      add :bio, :text
    end

    create unique_index(:profile, [:user_id])

    create index(:profile, [:inserted_at])
  end
end
