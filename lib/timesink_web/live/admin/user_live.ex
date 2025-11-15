defmodule TimesinkWeb.Admin.UserLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Account.User,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Account.User.changeset/3,
      create_changeset: &Timesink.Account.User.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

  @impl Backpex.LiveResource
  def singular_name, do: "Member"

  @impl Backpex.LiveResource
  def plural_name, do: "Members"

  @impl Backpex.LiveResource
  def can?(_assigns, :index, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, :show, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, :edit, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: false

  @impl Backpex.LiveResource
  def fields do
    [
      email: %{
        module: Backpex.Fields.Text,
        label: "Email"
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
        module: Backpex.Fields.MultiSelect,
        label: "Roles",
        options: fn _assigns ->
          [
            {"Admin", :admin},
            {"Creator", :creator}
          ]
        end
      }
    ]
  end
end
