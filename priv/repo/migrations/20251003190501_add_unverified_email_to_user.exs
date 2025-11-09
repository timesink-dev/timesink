defmodule Timesink.Repo.Migrations.AddUnverifiedEmailToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :unverified_email, :string
    end
  end
end
