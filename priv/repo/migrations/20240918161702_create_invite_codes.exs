defmodule Timesink.Repo.Migrations.CreateInviteCodes do
  use Ecto.Migration

  def change do
    create table(:invite_codes) do
      timestamps(type: :utc_datetime)

      add :code, :string, null: false
      add :is_sent, :boolean, null: false, default: false
      add :is_used, :boolean, null: false, default: false
      add :issuer_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:invite_codes, [:code])
  end
end
