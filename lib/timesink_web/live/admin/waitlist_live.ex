defmodule TimesinkWeb.Admin.WaitlistLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Waitlist.Applicant,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Waitlist.Applicant.changeset/3,
      create_changeset: &Timesink.Waitlist.Applicant.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

  @impl Backpex.LiveResource
  def singular_name, do: "Applicant"

  @impl Backpex.LiveResource
  def plural_name, do: "Applicants"

  @impl Backpex.LiveResource
  def can?(_assigns, :index, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: false

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
