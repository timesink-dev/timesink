defmodule Timesink.Repo.Migrations.CreateWaitlist do
  use Ecto.Migration

  def change do
    create table(:waitlist, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      timestamps type: :utc_datetime

      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :status, :string, null: false, default: "pending"
    end

    create unique_index(:waitlist, [:email])

    create constraint(:waitlist, :status_check,
             check: "status IN ('pending', 'invited', 'completed')"
           )
  end
end
