defmodule TimesinkWeb.Admin.CreativeLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Creative,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Creative.changeset/3,
      create_changeset: &Timesink.Cinema.Creative.changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "creatives",
      event_prefix: "creative_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Creative"

  @impl Backpex.LiveResource
  def plural_name, do: "Creatives"

  @impl Backpex.LiveResource
  def fields do
    [
      first_name: %{
        module: Backpex.Fields.Text,
        label: "First Name"
      },
      last_name: %{
        module: Backpex.Fields.Text,
        label: "Last Name"
      },
      profile: %{
        module: Backpex.Fields.BelongsTo,
        label: "Profile",
        display_field: :first_name,
        live_resource: TimesinkWeb.Admin.ProfileLive
      }
    ]
  end

  def item_query(query, :show, _assigns) do
    # get the user :first_name + :last_name from the profile
    doo =
      query
      |> join(:inner, [c], p in assoc(c, :profile))
      |> select([c, p], %{c | first_name: p.first_name, last_name: p.last_name})

    IO.puts(doo)

    query
  end
end
