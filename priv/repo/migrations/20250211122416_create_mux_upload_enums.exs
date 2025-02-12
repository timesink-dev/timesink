defmodule Timesink.Repo.Migrations.CreateMuxUploadEnums do
  use Ecto.Migration

  def up do
    execute """
      CREATE TYPE mux_upload_status AS ENUM (
        'waiting',
        'asset_created',
        'errored',
        'timed_out',
        'cancelled'
      )
    """
  end

  def down do
    execute "DROP TYPE mux_upload_status"
  end
end
