defmodule Timesink.Repo.Migrations.CreateTheaterComment do
  use Ecto.Migration

  def change do
    create table(:theater_comment, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      add :content, :text, null: false

      # polymorphic link to the thing being commented on for this flavor
      add :assoc_id, references(:theater, type: :uuid, on_delete: :delete_all), null: false

      # author (same pattern as your blog_post_comment)
      add :user_id, references(:user, type: :uuid, on_delete: :delete_all), null: false

      # 1-level threading (optional)
      add :parent_id, references(:theater_comment, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:theater_comment, [:assoc_id])
    create index(:theater_comment, [:user_id])
    create index(:theater_comment, [:parent_id])
    create index(:theater_comment, [:assoc_id, :inserted_at])
  end
end
