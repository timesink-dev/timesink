defmodule Timesink.Repo.Migrations.CreateAttachmentEnums do
  use Ecto.Migration

  def up do
    # Create Postgres enum attachment_schema
    execute """
      CREATE TYPE attachment_assoc_schema AS ENUM (
        'creative',
        'exhibition',
        'film_creative',
        'film',
        'genre',
        'profile',
        'showcase',
        'theater',
        'user'
      )
    """
  end

  def down do
    execute "DROP TYPE attachment_assoc_schema"
  end
end
