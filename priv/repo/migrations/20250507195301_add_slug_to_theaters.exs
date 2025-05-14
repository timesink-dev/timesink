defmodule Timesink.Repo.Migrations.AddSlugToTheaters do
  use Ecto.Migration

  def change do
    alter table(:theater) do
      add :slug, :string, null: false
    end

    create unique_index(:theater, [:slug])
  end
end
