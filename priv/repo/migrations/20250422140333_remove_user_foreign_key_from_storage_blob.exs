defmodule Timesink.Repo.Migrations.RemoveUserForeignKeyFromStorageBlob do
  use Ecto.Migration

  def change do
    alter table(:blob) do
      remove :user_id, references(:user, type: :uuid, on_delete: :delete_all)
    end
  end
end
