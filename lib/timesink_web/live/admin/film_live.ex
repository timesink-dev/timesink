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
      # directors: %{
      #   module: Backpex.Fields.HasMany,
      #   label: "Director",
      #   display_field: :role,
      #   searchable: false,
      #   live_resource: TimesinkWeb.Admin.UserLive
      # },
      # film_creative: %{
      #   module: Backpex.Fields.HasMany,
      #   label: "Film Creative",
      #   display_field: :role,
      #   searchable: false,
      #   live_resource: TimesinkWeb.Admin.FilmCreativeLive
      # },
      year: %{
        module: Backpex.Fields.Number,
        label: "Year"
      },
      synopsis: %{
        module: Backpex.Fields.Textarea,
        label: "Synopsis"
      },
      duration: %{
        module: Backpex.Fields.Number,
        label: "Duration (min)"
      },
      genres: %{
        module: Backpex.Fields.HasMany,
        label: "Genres",
        display_field: :name,
        searchable: false,
        live_resource: TimesinkWeb.Admin.GenreLive
      },
      format: %{
        module: Backpex.Fields.Select,
        label: "Format",
        options: [
          {"Digital", :digital},
          {"8mm", :"8mm"},
          {"16mm", :"16mm"},
          {"Super 16mm", :"Super 16mm"},
          {"35mm", :"35mm"},
          {"65mm", :"65mm"},
          {"70mm", :"70mm"}
        ]
      },
      color: %{
        module: Backpex.Fields.Select,
        label: "Color",
        options: [
          {"Color", :color},
          {"Black and White", :black_and_white},
          {"Sepia", :sepia},
          {"Monochrome", :monochrome},
          {"Partial Color", :partial_color},
          {"Technicolor", :technicolor}
        ]
      },
      aspect_ratio: %{
        module: Backpex.Fields.Text,
        label: "Aspect Ratio"
      }
    ]
  end
end
