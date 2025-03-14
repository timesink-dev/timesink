defmodule Timesink.Repo.Migrations.ChangeUserEmailToCitext do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    alter table(:user) do
      # Change email to citext for case-insensitive comparison
      modify :email, :citext, null: false
    end
  end

  def down do
    alter table(:user) do
      modify :email, :string, null: false
    end
  end
end
