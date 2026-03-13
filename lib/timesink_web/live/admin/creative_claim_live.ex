defmodule TimesinkWeb.Admin.CreativeClaimLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.CreativeClaim,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.CreativeClaim.changeset/3,
      create_changeset: &Timesink.Cinema.CreativeClaim.changeset/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

  alias Timesink.Cinema.CreativeClaims

  @impl Backpex.LiveResource
  def singular_name, do: "Creative Claim"

  @impl Backpex.LiveResource
  def plural_name, do: "Creative Claims"

  @impl Backpex.LiveResource
  def can?(_assigns, :index, _item), do: true
  def can?(_assigns, :show, _item), do: true

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: false

  @impl Backpex.LiveResource
  def item_actions(default_actions) do
    default_actions
    |> Map.put(:approve, %{
      module: TimesinkWeb.Admin.CreativeClaimLive.ApproveAction,
      only: [:pending]
    })
    |> Map.put(:reject, %{
      module: TimesinkWeb.Admin.CreativeClaimLive.RejectAction,
      only: [:pending]
    })
  end

  @impl Backpex.LiveResource
  def fields do
    [
      status: %{
        module: Backpex.Fields.Text,
        label: "Status",
        except: [:edit, :new]
      },
      creative_id: %{
        module: Backpex.Fields.Text,
        label: "Creative ID",
        except: [:edit, :new]
      },
      user_id: %{
        module: Backpex.Fields.Text,
        label: "Member ID",
        except: [:edit, :new]
      },
      message: %{
        module: Backpex.Fields.Textarea,
        label: "Message",
        except: [:edit, :new]
      }
    ]
  end
end

defmodule TimesinkWeb.Admin.CreativeClaimLive.ApproveAction do
  use Backpex.ItemAction

  alias Timesink.Cinema.CreativeClaims

  @impl Backpex.ItemAction
  def label(_assigns), do: "Approve"

  @impl Backpex.ItemAction
  def handle(_socket, item, _params) do
    case CreativeClaims.approve_claim(item) do
      {:ok, _claim} -> {:ok, "Claim approved."}
      {:error, _reason} -> {:error, "Could not approve claim."}
    end
  end
end

defmodule TimesinkWeb.Admin.CreativeClaimLive.RejectAction do
  use Backpex.ItemAction

  alias Timesink.Cinema.CreativeClaims

  @impl Backpex.ItemAction
  def label(_assigns), do: "Reject"

  @impl Backpex.ItemAction
  def handle(_socket, item, _params) do
    case CreativeClaims.reject_claim(item) do
      {:ok, _claim} -> {:ok, "Claim rejected."}
      {:error, _reason} -> {:error, "Could not reject claim."}
    end
  end
end
