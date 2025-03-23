defmodule Timesink.Repo.Migrations.CreateBlobEnums do
  use Ecto.Migration

  def up do
    execute """
      CREATE TYPE blob_service AS ENUM (
        'mux',
        's3'
      )
    """
  end

  def down do
    execute "DROP TYPE blob_service"
  end
end
