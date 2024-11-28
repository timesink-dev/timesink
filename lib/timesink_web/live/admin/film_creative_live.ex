defmodule TimesinkWeb.Admin.FilmCreativeLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.FilmCreative,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.FilmCreative.changeset/3,
      create_changeset: &Timesink.Cinema.FilmCreative.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "film_creatives",
      event_prefix: "film_creative_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Film Creative"

  @impl Backpex.LiveResource
  def plural_name, do: "Film Creatives"

  @impl Backpex.LiveResource
  def fields do
    [
      film: %{
        module: Backpex.Fields.BelongsTo,
        label: "Film",
        display_field: :title,
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmLive
      },
      creative: %{
        module: Backpex.Fields.BelongsTo,
        label: "Creative",
        display_field: :last_name,
        searchable: false,
        live_resource: TimesinkWeb.Admin.UserLive
      },
      role: %{
        module: Backpex.Fields.Text,
        label: "Role"
      }
    ]
  end
end
