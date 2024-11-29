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
  def panels do
    [theaters: "Theaters"]
  end

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
      films: %{
        module: Backpex.Fields.HasManyThrough,
        label: "Theaters",
        display_field: :title,
        except: [:index],
        orderable: false,
        searchable: false,
        live_resource: TimesinkWeb.Admin.ExhibitionLiveLive,
        pivot_fields: [
          theater: %{
            module: Backpex.Fields.Select,
            label: "Theater",
            options: [
              {"Theater 1", 1},
              {"Theater 2", 2},
              {"Theater 3", 3}
            ]
          },
          film: %{
            module: Backpex.Fields.Select,
            label: "Film",
            options: [
              {"Film 1", 1},
              {"Film 2", 2},
              {"Film 3", 3}
            ]
          }
        ]
      },
      # exhibitions: %{
      #   module: TimesinkWeb.Admin.Fields.Theaters,
      #   type: :assoc,
      #   label: "Theaters",
      #   panel: :theaters,
      #   child_fields: [
      #     theater: %{
      #       module: Backpex.Fields.Text,
      #       label: "Theater",
      #       options: get_theater_options()
      #     }
      #   ]
      # },
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
      }
    ]
  end
end
