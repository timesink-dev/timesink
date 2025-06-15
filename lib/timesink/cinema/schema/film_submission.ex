defmodule Timesink.Cinema.FilmSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  @type status_review :: :received | :under_review | :accepted | :rejected
  @statuses_review [:received, :under_review, :accepted, :rejected]
  def statuses_review, do: @statuses_review

  @type t :: %{
          __struct__: __MODULE__,
          id: Ecto.UUID.t(),
          title: String.t(),
          year: integer(),
          duration_min: integer(),
          synopsis: String.t(),
          video_url: String.t(),
          video_pw: String.t() | nil,
          contact_name: String.t(),
          contact_email: String.t(),
          status_review: status_review(),
          status_review_updated_at: DateTime.t() | nil,
          review_notes: String.t() | nil,
          stripe_id: String.t() | nil,
          submitted_by_id: Ecto.UUID.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "film_submission" do
    field :title, :string
    field :year, :integer
    field :duration_min, :integer
    field :synopsis, :string
    field :video_url, :string
    field :video_pw, :string

    field :contact_name, :string
    field :contact_email, :string

    field :status_review, Ecto.Enum, values: @statuses_review, default: :received
    field :status_review_updated_at, :utc_datetime_usec
    field :review_notes, :string

    field :stripe_id, :string

    belongs_to :submitted_by, Timesink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @valid_statuses ~w(received under_review accepted rejected)

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [
      :title,
      :year,
      :duration_min,
      :synopsis,
      :video_url,
      :video_pw,
      :contact_name,
      :contact_email,
      :status_review,
      :review_notes,
      :stripe_id,
      :submitted_by_id
    ])
    |> validate_required([
      :title,
      :year,
      :duration_min,
      :synopsis,
      :video_url,
      :contact_name,
      :contact_email,
      :status_review
    ])
    |> validate_inclusion(:status_review, @valid_statuses)
    |> maybe_set_status_timestamp()
  end

  defp maybe_set_status_timestamp(changeset) do
    if get_change(changeset, :status_review) do
      put_change(changeset, :status_review_updated_at, DateTime.utc_now())
    else
      changeset
    end
  end
end
