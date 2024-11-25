defmodule TimesinkWeb.Admin.ShowcaseLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Showcase,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Showcase.changeset/3,
      create_changeset: &Timesink.Cinema.Showcase.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "showcases",
      event_prefix: "showcase_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Showcase"

  @impl Backpex.LiveResource
  def plural_name, do: "Showcases"

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title"
      },
      description: %{
        module: Backpex.Fields.Text,
        label: "Description"
      }
    ]
  end
end
