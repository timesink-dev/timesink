defmodule TimesinkWeb.Admin.FilmLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Film,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Film.changeset/3,
      create_changeset: &Timesink.Cinema.Film.changeset/3
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

  def panels do
    [creators: "Creators", specs: "Specifications"]
  end

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
      directors: %{
        module: Backpex.Fields.HasMany,
        panel: :creators,
        label: "Directors",
        display_field: :role,
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmCreativeLive
      },
      producers: %{
        module: Backpex.Fields.HasMany,
        panel: :creators,
        label: "Producers",
        display_field: :role,
        except: [:index],
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmCreativeLive
      },
      writers: %{
        module: Backpex.Fields.HasMany,
        panel: :creators,
        label: "Writers",
        display_field: :role,
        except: [:index],
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmCreativeLive
      },
      cast: %{
        module: Backpex.Fields.HasMany,
        panel: :creators,
        label: "Cast",
        display_field: :role,
        except: [:index],
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmCreativeLive
      },
      crew: %{
        module: Backpex.Fields.HasMany,
        panel: :creators,
        label: "Crew",
        display_field: :role,
        except: [:index],
        searchable: false,
        live_resource: TimesinkWeb.Admin.FilmCreativeLive
      },
      synopsis: %{
        module: Backpex.Fields.Textarea,
        label: "Synopsis"
      },
      duration: %{
        module: Backpex.Fields.Number,
        label: "Duration (min)",
        panel: :specs
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
        panel: :specs,
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
        panel: :specs,
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
        panel: :specs,
        label: "Aspect Ratio"
      }
    ]
  end
end
