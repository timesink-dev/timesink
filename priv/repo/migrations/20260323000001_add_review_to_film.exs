defmodule Timesink.Repo.Migrations.AddReviewToFilm do
  use Ecto.Migration

  def change do
    alter table(:film) do
      add :review, :text
    end
  end
end
