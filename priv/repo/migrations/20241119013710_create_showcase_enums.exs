defmodule Timesink.Repo.Migrations.CreateShowcaseEnums do
  use Ecto.Migration

  def up do
    # Create Postgres enum showcase_status
    execute """
      CREATE TYPE showcase_status AS ENUM (
        'upcoming',
        'active',
        'archived'
      )
    """
  end

  def down do
    execute "DROP TYPE showcase_status"
  end
end
