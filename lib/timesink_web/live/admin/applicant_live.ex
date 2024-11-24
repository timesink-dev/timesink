defmodule TimesinkWeb.Admin.ApplicantLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Waitlist.Applicant,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Waitlist.Applicant.update_changeset/3,
      create_changeset: &Timesink.Waitlist.Applicant.create_changeset/3,
      # update_changeset: &MyApp.Waitlist.Applicant.update_changeset/3,
      # create_changeset: &Timesink.Waitlist.Applicant.create_changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "applicants",
      event_prefix: "applicant_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Applicant"

  @impl Backpex.LiveResource
  def plural_name, do: "Applicants"

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title"
      },
      views: %{
        module: Backpex.Fields.Number,
        label: "Views"
      }
    ]
  end
end
