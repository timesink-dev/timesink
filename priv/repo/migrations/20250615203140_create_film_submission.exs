defmodule Timesink.Repo.Migrations.CreateFilmSubmission do
  use Ecto.Migration

  def change do
    create table(:film_submission, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      add :title, :string, null: false
      add :year, :integer, null: false
      add :duration_min, :integer, null: false
      add :synopsis, :text, null: false
      add :video_url, :string, null: false
      add :video_pw, :string

      add :contact_name, :string
      add :contact_email, :string

      add :status_review, :film_submission_status_review, null: false, default: "received"
      add :status_review_updated_at, :utc_datetime_usec
      add :review_notes, :text

      add :stripe_id, :string

      add :submitted_by_id, references(:user, type: :uuid, on_delete: :nilify_all), null: true

      timestamps type: :utc_datetime
    end

    create index(:film_submission, [:submitted_by_id])
    create index(:film_submission, [:status_review])
  end
end
