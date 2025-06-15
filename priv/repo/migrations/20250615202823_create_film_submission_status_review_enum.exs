defmodule Timesink.Repo.Migrations.CreateFilmSubmissionStatusReviewEnum do
  use Ecto.Migration

  def up do
    execute """
      CREATE TYPE film_submission_status_review AS ENUM (
        'received',
        'under_review',
        'accepted',
        'rejected'
      )
    """
  end

  def down do
    execute "DROP TYPE film_submission_status_review"
  end
end
