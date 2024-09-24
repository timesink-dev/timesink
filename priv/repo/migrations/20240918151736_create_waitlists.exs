defmodule Timesink.Repo.Migrations.CreateWaitlists do
  use Ecto.Migration

  def change do
    create table(:waitlists) do
      timestamps(type: :utc_datetime)

      add :email, :string, null: false
      # Possible statuses: pending, invited, processed
      add :status, :string, null: false, default: "pending"

      # Foreign key to invite_codes table
      add :invite_code_id, references(:invite_codes, on_delete: :nilify_all)

      timestamps()
    end

    # Ensure unique email per waitlist entry
    create unique_index(:waitlists, [:email])

    # Add check constraint for the status field
    execute("""
    ALTER TABLE waitlists
    ADD CONSTRAINT status_check
    CHECK (status IN ('pending', 'invited', 'processed'))
    """)
  end
end
