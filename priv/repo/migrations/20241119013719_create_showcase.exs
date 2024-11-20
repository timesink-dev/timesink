defmodule Timesink.Repo.Migrations.CreateShowcase do
  use Ecto.Migration

  def change do
    create table(:showcase, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      add :end_time, :utc_datetime
      add :start_time, :utc_datetime

      timestamps type: :utc_datetime

      add :status, :string, null: false
      add :title, :string, null: false
    end

    create constraint(:showcase, :status_check,
             check: "status IN ('upcoming', 'active', 'archived')"
           )

    # Add a unique index for the "active" status
    create unique_index(:showcase, [:status],
             where: "status = 'active'",
             name: :unique_active_showcase
           )

    create index(:showcase, [:inserted_at])

    # Do we need this multi-column index? for filtering/searching?
    create index(:showcase, [:status, :title])
  end
end
