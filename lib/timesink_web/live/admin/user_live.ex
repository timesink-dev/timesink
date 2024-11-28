defmodule TimesinkWeb.Admin.UserLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Accounts.User,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Accounts.User.changeset/3,
      create_changeset: &Timesink.Accounts.User.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin},
    pubsub: [
      name: Timesink.PubSub,
      topic: "users",
      event_prefix: "user_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Member"

  @impl Backpex.LiveResource
  def plural_name, do: "Members"

  @impl Backpex.LiveResource
  def fields do
    [
      email: %{
        module: Backpex.Fields.Text,
        label: "Email"
      },
      password: %{
        module: Backpex.Fields.Text,
        label: "Password"
      },
      username: %{
        module: Backpex.Fields.Text,
        label: "Username"
      },
      first_name: %{
        module: Backpex.Fields.Text,
        label: "First Name"
      },
      last_name: %{
        module: Backpex.Fields.Text,
        label: "Last Name"
      },
      roles: %{
        module: Backpex.Fields.Select,
        label: "Roles",
        options: [
          {"Admin", :admin},
          {"Creator", :creator}
        ]
      }
    ]
  end
end
