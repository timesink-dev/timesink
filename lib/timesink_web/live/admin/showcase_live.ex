defmodule TimesinkWeb.Admin.ShowcaseLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Showcase,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Showcase.changeset/3,
      create_changeset: &Timesink.Cinema.Showcase.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

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
        module: Backpex.Fields.Textarea,
        label: "Description"
      },
      start_at: %{
        module: Backpex.Fields.DateTime,
        label: "Start Date and Time (UTC)"
      },
      end_at: %{
        module: Backpex.Fields.DateTime,
        label: "End Date and Time (UTC)"
      },
      status: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options:
          Enum.map(Timesink.Cinema.Showcase.statuses(), fn status ->
            {String.capitalize(Atom.to_string(status)), status}
          end)
      }
    ]
  end

  @impl Backpex.LiveResource
  def on_item_created(socket, item) do
    require Logger
    Logger.info("Showcase #{item.id} created via Backpex, reloading theater cache")
    Timesink.Cinema.TheaterScheduler.reload()
    socket
  end

  @impl Backpex.LiveResource
  def on_item_updated(socket, item) do
    require Logger
    Logger.info("Showcase #{item.id} updated via Backpex, reloading theater cache")
    Timesink.Cinema.TheaterScheduler.reload()
    socket
  end
end
