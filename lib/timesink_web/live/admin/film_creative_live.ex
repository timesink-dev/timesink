defmodule TimesinkWeb.Admin.FilmCreativeLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.FilmCreative,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.FilmCreative.changeset/3,
      create_changeset: &Timesink.Cinema.FilmCreative.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

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
        module: Backpex.Fields.Select,
        options: [
          {"Director", :director},
          {"Producer", :producer},
          {"Writer", :writer},
          {"Cast", :cast},
          {"Crew", :crew}
        ],
        label: "Role"
      },
      subrole: %{
        module: Backpex.Fields.Text,
        label: "Sub Role",
        visible: fn
          %{live_action: :new} = assigns ->
            role = Map.get(assigns.changeset.changes, :role)
            role in [:cast, :crew]

          %{live_action: :edit} = assigns ->
            current_role = Map.get(assigns.form.data, :role)
            is_current_cast_or_crew = current_role in [:cast, :crew]

            changed_role = Map.get(assigns.changeset.changes, :role)

            is_current_cast_or_crew || changed_role in [:cast, :crew]

          _assigns ->
            true
        end
      }
    ]
  end
end
