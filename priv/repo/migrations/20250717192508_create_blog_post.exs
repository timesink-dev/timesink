defmodule Timesink.Repo.Migrations.CreateBlogPost do
  use Ecto.Migration

  def change do
    create table(:blog_post, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :text, null: false
      add :author, :string, null: false
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_post, [:slug])
  end
end
