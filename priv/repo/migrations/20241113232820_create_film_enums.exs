defmodule Timesink.Repo.Migrations.CreateTableFilmEnums do
  use Ecto.Migration

  def up do
    # Create Postgres enum film_color
    execute """
      CREATE TYPE film_color AS ENUM (
        'black_and_white',
        'sepia',
        'monochrome',
        'partially_colorized',
        'color'
      )
    """

    # Create Postgres enum film_format
    execute """
      CREATE TYPE film_format AS ENUM (
        '8mm',
        '16mm',
        '35mm',
        '65mm',
        '70mm',
        'digital'
      )
    """
  end

  def down do
    execute "DROP TYPE film_color"
    execute "DROP TYPE film_format"
  end
end
