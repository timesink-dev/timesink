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
      film_id: %{
        module: Backpex.Fields.Select,
        label: "Film",
        options: fn -> Timesink.Cinema.Film |> Timesink.Cinema.Film.list_films() end
      },
      showcase_id: %{
        module: Backpex.Fields.Select,
        label: "Showcase",
        options: fn -> Timesink.Cinema.Showcase |> Timesink.Cinema.Showcase.list_showcases() end
      },
      theater_id: %{
        module: Backpex.Fields.Select,
        label: "Theater",
        options: fn -> Timesink.Cinema.Theater |> Timesink.Cinema.Theater.list_theaters() end
      }
    ]
  end
end
