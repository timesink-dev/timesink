defmodule TimesinkWeb.Admin.FilmSubmissionLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.FilmSubmission,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.FilmSubmission.changeset/3,
      create_changeset: &Timesink.Cinema.FilmSubmission.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "film_submissions",
      event_prefix: "film_submission_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Film Submission"

  @impl Backpex.LiveResource
  def plural_name, do: "Film Submissions"

  @impl Backpex.LiveResource
  def can?(_assigns, :index, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, :show, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, :edit, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: false

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title"
      },
      synopsis: %{
        module: Backpex.Fields.Textarea,
        label: "Synopsis"
      },
      video_url: %{
        module: Backpex.Fields.Text,
        label: "Video URL"
      },
      video_pw: %{
        module: Backpex.Fields.Text,
        label: "Video Password"
      },
      year: %{
        module: Backpex.Fields.Number,
        label: "Year"
      },
      duration_min: %{
        module: Backpex.Fields.Number,
        label: "Duration (min)"
      },
      contact_name: %{
        module: Backpex.Fields.Text,
        label: "Contact Name"
      },
      contact_email: %{
        module: Backpex.Fields.Text,
        label: "Contact Email"
      },
      status_review: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options: fn _assigns ->
          [
            {"Pending", :received},
            {"Under Review", :under_review},
            {"Accepted", :accepted},
            {"Rejected", :rejected}
          ]
        end
      },
      review_notes: %{
        module: Backpex.Fields.Textarea,
        label: "Review Notes"
      }
    ]
  end
end
