defmodule TimesinkWeb.Admin.CreativeLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.Creative,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.Creative.changeset/3,
      create_changeset: &Timesink.Cinema.Creative.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

  import Ecto.Query, only: [dynamic: 2]

  @impl Backpex.LiveResource
  def singular_name, do: "Creative"

  @impl Backpex.LiveResource
  def plural_name, do: "Creatives"

  @impl Backpex.LiveResource
  def fields do
    [
      full_name: %{
        module: Backpex.Fields.Text,
        label: "Full Name",
        searchable: true,
        except: [:new, :edit],
        select: dynamic([creative: c], fragment("concat(?, ' ', ?)", c.first_name, c.last_name))
      },
      first_name: %{
        module: Backpex.Fields.Text,
        label: "First Name"
      },
      last_name: %{
        module: Backpex.Fields.Text,
        label: "Last Name"
      }
    ]
  end
end
