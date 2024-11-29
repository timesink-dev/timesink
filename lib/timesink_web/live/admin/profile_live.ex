defmodule TimesinkWeb.Admin.ProfileLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Accounts.Profile,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Accounts.Profile.changeset/3,
      create_changeset: &Timesink.Accounts.Profile.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "profiles",
      event_prefix: "profile_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Profile"

  @impl Backpex.LiveResource
  def plural_name, do: "Profiles"

  @impl Backpex.LiveResource
  def fields do
    [
      bio: %{
        module: Backpex.Fields.Text,
        label: "Bio"
      },
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "User",
        display_field: :email,
        live_resource: TimesinkWeb.Admin.UserLive
      }
    ]
  end
end
