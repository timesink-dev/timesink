defmodule TimesinkWeb.Admin.FilmLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Film,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Film.changeset/3,
      create_changeset: &Timesink.Cinema.Film.changeset/3
      # update_changeset: &MyApp.Waitlist.Applicant.update_changeset/3,
      # create_changeset: &Timesink.Waitlist.Applicant.create_changeset/3,
      # item_query: &__MODULE__.item_query/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "films",
      event_prefix: "film_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Film"

  @impl Backpex.LiveResource
  def plural_name, do: "Films"

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title"
      },
      year: %{
        module: Backpex.Fields.Number,
        label: "Year"
      },
      duration: %{
        module: Backpex.Fields.Number,
        label: "Duration"
      }
    ]
  end

  # def item_query(query, :index, _assigns) do
  #   query |> where([f], f.id > 0)
  # end
end
