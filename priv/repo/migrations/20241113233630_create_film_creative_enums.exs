defmodule Timesink.Repo.Migrations.CreateTableFilmCreativeEnums do
  use Ecto.Migration

  def up do
    # Create Postgres enum film_creative_role
    execute """
      CREATE TYPE film_creative_role AS ENUM (
        'director',
        'producer',
        'writer',
        'cast',
        'crew'
      )
    """
  end

  def down do
    execute "DROP TYPE film_creative_role"
  end
end
