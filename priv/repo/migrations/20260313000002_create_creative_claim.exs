defmodule Timesink.Repo.Migrations.CreateCreativeClaim do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE creative_claim_status AS ENUM ('pending', 'approved', 'rejected')"
    drop_query = "DROP TYPE creative_claim_status"
    execute(create_query, drop_query)

    create table(:creative_claim, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      add :user_id, references(:user, type: :uuid, on_delete: :delete_all), null: false
      add :creative_id, references(:creative, type: :uuid, on_delete: :delete_all), null: false

      add :status, :creative_claim_status, null: false, default: "pending"
      add :message, :text

      timestamps(type: :utc_datetime)
    end

    create index(:creative_claim, [:user_id])
    create index(:creative_claim, [:creative_id])
    create index(:creative_claim, [:status])
    # Prevent a user from submitting duplicate claims for the same creative
    create unique_index(:creative_claim, [:user_id, :creative_id])
  end
end
