defmodule Timesink.Repo.Migrations.AddStartOffsetMinutesToTheaters do
  use Ecto.Migration

  def change do
    alter table(:theater) do
      add :start_offset_minutes, :integer, default: 0, null: false
    end
  end
end
