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
    default_actions ++
      [
        approve: %{
          module: TimesinkWeb.Admin.CreativeClaimLive.ApproveAction,
          only: [:row]
        },
        reject: %{
          module: TimesinkWeb.Admin.CreativeClaimLive.RejectAction,
          only: [:row]
        }
      ]
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
  use BackpexWeb, :item_action

  alias Timesink.Cinema.CreativeClaims

  @impl Backpex.ItemAction
  def icon(assigns, _item) do
    ~H"""
    <Backpex.HTML.CoreComponents.icon
      name="hero-check"
      class="h-5 w-5 cursor-pointer transition duration-75 hover:scale-110 hover:text-emerald-500"
    />
    """
  end

  @impl Backpex.ItemAction
  def label(_assigns, _item), do: "Approve"

  @impl Backpex.ItemAction
  def confirm(_assigns),
    do:
      "Are you sure you want to approve this claim? This will link the creative to the member's account."

  @impl Backpex.ItemAction
  def handle(socket, [item | _], _params) do
    case CreativeClaims.approve_claim(item) do
      {:ok, _claim} ->
        socket |> put_flash(:info, "Claim approved.") |> ok()

      {:error, _reason} ->
        socket |> put_flash(:error, "Could not approve claim.") |> ok()
    end
  end
end

defmodule TimesinkWeb.Admin.CreativeClaimLive.RejectAction do
  use BackpexWeb, :item_action

  alias Timesink.Cinema.CreativeClaims

  @impl Backpex.ItemAction
  def icon(assigns, _item) do
    ~H"""
    <Backpex.HTML.CoreComponents.icon
      name="hero-x-mark"
      class="h-5 w-5 cursor-pointer transition duration-75 hover:scale-110 hover:text-red-500"
    />
    """
  end

  @impl Backpex.ItemAction
  def label(_assigns, _item), do: "Reject"

  @impl Backpex.ItemAction
  def confirm(_assigns), do: "Are you sure you want to reject this claim?"

  @impl Backpex.ItemAction
  def handle(socket, [item | _], _params) do
    case CreativeClaims.reject_claim(item) do
      {:ok, _claim} ->
        socket |> put_flash(:info, "Claim rejected.") |> ok()

      {:error, _reason} ->
        socket |> put_flash(:error, "Could not reject claim.") |> ok()
    end
  end
end
