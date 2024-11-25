defmodule TimesinkWeb.Admin.GenresLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Genre,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Genre.changeset/3,
      create_changeset: &Timesink.Cinema.Genre.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "genres",
      event_prefix: "genre_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Genre"

  @impl Backpex.LiveResource
  def plural_name, do: "Genres"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      }
    ]
  end
end
