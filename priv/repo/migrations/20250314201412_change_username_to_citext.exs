defmodule Timesink.Repo.Migrations.ChangeUsernameToCitext do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    alter table(:user) do
      modify :username, :citext, null: false
    end
  end

  def down do
    alter table(:user) do
      modify :username, :string, null: false
    end
  end
end
