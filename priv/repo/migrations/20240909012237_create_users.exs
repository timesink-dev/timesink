defmodule Timesink.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :is_active, :boolean, null: false, default: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :username, :string, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :roles, {:array, :string}, null: false, default: []
    end

    create unique_index(:users, [:email])

    create index(:users, [:inserted_at])
    create index(:users, [:first_name])
    create index(:users, [:last_name])
  end
end
