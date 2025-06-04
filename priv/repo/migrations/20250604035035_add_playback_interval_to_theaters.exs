defmodule Timesink.Repo.Migrations.AddPlaybackIntervalToTheaters do
  use Ecto.Migration

  def change do
    alter table(:theater) do
      add :playback_interval_minutes, :integer, default: 15, null: false
    end
  end
end
