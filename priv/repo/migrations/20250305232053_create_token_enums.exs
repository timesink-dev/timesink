defmodule Timesink.Repo.Migrations.CreateTokenEnums do
  use Ecto.Migration

  def up do
    execute """
      CREATE TYPE token_status AS ENUM (
        'valid',
        'invalid',
      )
    """

    execute """
      CREATE TYPE token_kind AS ENUM (
        'invite',
        'email_verification',
        'password_reset'
      )
    """
  end

  def down do
    execute "DROP TYPE token_status"
    execute "DROP TYPE token_kind"
  end
end
