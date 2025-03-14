defmodule Timesink.Repo.Migrations.AddEmailToToken do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    alter table(:token) do
      add :email, :citext, null: true
    end

    # Lookup tokens for a user
    create index(:token, [:user_id])

    # Lookup tokens by waitlist
    create index(:token, [:waitlist_id])

    # Lookup tokens by email for onboarding applicants
    create index(:token, [:email])
  end

  def down do
    alter table(:token) do
      remove :email
    end

    drop index(:token, [:user_id])
    drop index(:token, [:waitlist_id])
  end
end
