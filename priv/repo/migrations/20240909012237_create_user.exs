defmodule Timesink.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :is_active, :boolean, null: false, default: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :username, :string, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :roles, {:array, :string}, null: false, default: []
    end

    create unique_index(:user, [:email])

    create index(:user, [:inserted_at])
    create index(:user, [:first_name])
    create index(:user, [:last_name])
  end
end
