defmodule Timesink.Repo.Migrations.CreateAttachmentEnums do
  use Ecto.Migration

  def up do
    execute """
      CREATE TYPE attachment_schema AS ENUM (
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
    execute "DROP TYPE attachment_schema"
  end
end
