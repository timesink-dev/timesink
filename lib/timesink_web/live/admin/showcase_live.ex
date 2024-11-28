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
        module: Backpex.Fields.Textarea,
        label: "Description"
      },
      start_at: %{
        module: Backpex.Fields.DateTime,
        label: "Start Date and Time"
      },
      end_at: %{
        module: Backpex.Fields.DateTime,
        label: "End Date and Time"
      },
      status: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options:
          Enum.map(Timesink.Cinema.Showcase.statuses(), fn status ->
            {String.capitalize(Atom.to_string(status)), status}
          end)
      },
      # list all existign theaters (no rel to showcase), and then render each exhibition associated with that theater and this showcase
      # theaters: %{
      #   module: Backpex.Fields.InlineCRUD,
      #   label: "Theaters",
      #   live_resource: TimesinkWeb.Admin.TheaterLive
      # },
      exhibitions: %{
        module: Backpex.Fields.HasMany,
        label: "Exhibitions",
        # get the film title from the exhibition
        display_field: :film_title,
        live_resource: TimesinkWeb.Admin.ExhibitionLive,
        options_query: fn query, _field ->
          from e in query,
            # Join the film association
            join: f in assoc(e, :film),
            # Include the film title as a virtual field
            select: %{e | film_title: f.title}
        end
      }
    ]
  end
end
