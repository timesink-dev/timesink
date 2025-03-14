defmodule Timesink.Repo.Migrations.AddTokenTable do
  use Ecto.Migration

  def change do
    create table(:token, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      add :kind, :token_kind
      add :secret, :string
      add :status, :token_status, default: "valid"
      add :expires_at, :utc_datetime
      add :user_id, references(:user, type: :uuid, on_delete: :delete_all)
      add :waitlist_id, references(:waitlist, type: :uuid, on_delete: :delete_all)

      timestamps type: :utc_datetime
    end

    create index(:token, [:secret], unique: true)
  end
end
