defmodule Timesink.Repo.Migrations.MakeTokenSecretNonNullable do
  use Ecto.Migration

  def up do
    # Ensure no NULL values exist before applying NOT NULL constraint
    execute "UPDATE token SET secret = gen_random_uuid() WHERE secret IS NULL"

    # Alter the column to make it NOT NULL
    alter table(:token) do
      modify :secret, :string, null: false
      modify :kind, :token_kind, null: false
    end
  end

  def down do
    # Allow NULL values again (rolling back)
    alter table(:token) do
      modify :secret, :string, null: true
      modify :kind, :token_kind, null: true
    end
  end
end
