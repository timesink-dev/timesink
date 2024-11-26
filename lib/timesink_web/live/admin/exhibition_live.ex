defmodule TimesinkWeb.Admin.ExhibitionLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Exhibition,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Exhibition.changeset/3,
      create_changeset: &Timesink.Cinema.Exhibition.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "exhibitions",
      event_prefix: "exhibition_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Exhibition"

  @impl Backpex.LiveResource
  def plural_name, do: "Exhibitions"

  @impl Backpex.LiveResource
  def fields do
    [
      film: %{
        module: Backpex.Fields.BelongsTo,
        label: "Film",
        live_resource: TimesinkWeb.Admin.FilmLive,
        display_field: :title
      },
      showcase: %{
        module: Backpex.Fields.BelongsTo,
        label: "Showcase",
        live_resource: TimesinkWeb.Admin.ShowcaseLive,
        display_field: :title
      },
      theater: %{
        module: Backpex.Fields.BelongsTo,
        label: "Theater",
        live_resource: TimesinkWeb.Admin.TheaterLive,
        display_field: :name
      }
    ]
  end
end
