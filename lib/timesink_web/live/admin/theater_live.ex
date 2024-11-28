defmodule TimesinkWeb.Admin.TheaterLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Theater,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Theater.changeset/3,
      create_changeset: &Timesink.Cinema.Theater.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "theaters",
      event_prefix: "theater_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Theater"

  @impl Backpex.LiveResource
  def plural_name, do: "Theaters"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      description: %{
        module: Backpex.Fields.Text,
        label: "Description"
      }
    ]
  end
end
