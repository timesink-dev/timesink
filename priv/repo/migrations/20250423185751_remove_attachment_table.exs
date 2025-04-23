defmodule Timesink.Repo.Migrations.RemoveAttachmentTable do
  use Ecto.Migration

  def change do
    drop table(:attachment)
  end
end
