defmodule Timesink.Repo.Migrations.AddUserIdToCreative do
  use Ecto.Migration

  def change do
    alter table(:creative) do
      add :user_id, references(:user, type: :uuid, on_delete: :nilify_all)
      remove :profile_id
    end

    create unique_index(:creative, [:user_id])
  end
end
