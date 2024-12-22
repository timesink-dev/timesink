defmodule Timesink.Repo.Migrations.CreateFile do
  use Ecto.Migration

  def change do
    create table(:file, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      timestamps type: :utc_datetime

      add :user_id, references(:user, type: :uuid, on_delete: :delete_all)
      add :name, :string, null: false
      add :size, :integer, null: false
      add :content_type, :string
      add :content_hash, :string
      add :content, :string, null: false
    end

    create unique_index(:file, [:name])
    create unique_index(:file, [:hash])
  end
end
