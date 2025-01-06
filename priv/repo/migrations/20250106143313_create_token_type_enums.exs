defmodule Timesink.Repo.Migrations.CreateTokenTypeEnums do
  use Ecto.Migration

  def up do
    # Create Postgres enum showcase_status
    execute """
      CREATE TYPE token_type AS ENUM (
        'session',
        'reset_password',
        'onboarding_invite'
      )
    """
  end

  def down do
    execute "DROP TYPE token_type"
  end
end
