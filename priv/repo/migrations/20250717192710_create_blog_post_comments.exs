defmodule Timesink.Repo.Migrations.CreateBlogPostComments do
  use Ecto.Migration

  def change do
    create table(:blog_post_comment, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      add :content, :text, null: false
      add :assoc_id, references(:blog_post, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:user, type: :uuid, on_delete: :delete_all), null: false
      add :parent_id, references(:blog_post_comment, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:blog_post_comment, [:assoc_id])
    create index(:blog_post_comment, [:user_id])
    create index(:blog_post_comment, [:parent_id])
  end
end
