defmodule TimesinkWeb.Admin.CreativeLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Creative,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Creative.changeset/3,
      create_changeset: &Timesink.Cinema.Creative.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "creatives",
      event_prefix: "creative_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Creative"

  @impl Backpex.LiveResource
  def plural_name, do: "Creatives"

  @impl Backpex.LiveResource
  def fields do
    [
      first_name: %{
        module: Backpex.Fields.Text,
        label: "First Name"
      },
      last_name: %{
        module: Backpex.Fields.Text,
        label: "Last Name"
      },
      profile: %{
        module: Backpex.Fields.BelongsTo,
        label: "Profile",
        display_field: :username
      }
    ]
  end
end
