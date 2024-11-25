defmodule TimesinkWeb.Admin.WaitlistLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Waitlist.Applicant,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Waitlist.Applicant.changeset/3,
      create_changeset: &Timesink.Waitlist.Applicant.changeset/3,
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
      first_name: %{
        module: Backpex.Fields.Text,
        label: "First name"
      },
      last_name: %{
        module: Backpex.Fields.Text,
        label: "Last name"
      },
      email: %{
        module: Backpex.Fields.Text,
        label: "Email"
      }
    ]
  end
end
