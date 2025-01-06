defmodule Timesink.Repo.Migrations.CreateToken do
  use Ecto.Migration

  def change do
    use Ecto.Migration

    def change do
      create table(:token, primary_key: false) do
        add :id, :uuid, null: false, primary_key: true
        add :token, :binary, null: false
        add :type, :token_type, null: false
        add :sent_to, :string
        add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: true

        add :applicant_id, references(:applicants, type: :uuid, on_delete: :delete_all),
          null: true

        timestamps(type: :utc_datetime, updated_at: false)
      end

      create unique_index(:token, [:token, :type])
      create index(:token, [:user_id])
      create index(:token, [:applicant_id])
    end
  end
end
