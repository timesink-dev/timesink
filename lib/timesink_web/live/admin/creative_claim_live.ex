defmodule TimesinkWeb.Admin.CreativeClaimLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Timesink.Cinema.CreativeClaim,
      repo: Timesink.Repo,
      update_changeset: &Timesink.Cinema.CreativeClaim.changeset/3,
      create_changeset: &Timesink.Cinema.CreativeClaim.changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {TimesinkWeb.Layouts, :admin}

  import Ecto.Query, only: [dynamic: 2, join: 5, as: 1]
  alias Timesink.Cinema.CreativeClaims

  def item_query(query, _live_action, _assigns) do
    query
    |> join(:left, [claim], c in assoc(claim, :creative), as: :creative)
    |> join(:left, [claim], u in assoc(claim, :user), as: :member)
  end

  @impl Backpex.LiveResource
  def singular_name, do: "Creative Claim"

  @impl Backpex.LiveResource
  def plural_name, do: "Creative Claims"

  @impl Backpex.LiveResource
  def can?(_assigns, :index, _item), do: true
  def can?(_assigns, :show, _item), do: true
  def can?(_assigns, :edit, _item), do: true

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
      creative_name: %{
        module: Backpex.Fields.Text,
        label: "Creative",
        except: [:new],
        readonly: true,
        select: dynamic([creative: c], fragment("concat(?, ' ', ?)", c.first_name, c.last_name))
      },
      member_name: %{
        module: Backpex.Fields.Text,
        label: "Member",
        except: [:new],
        readonly: true,
        select: dynamic([member: u], fragment("concat(?, ' ', ?)", u.first_name, u.last_name))
      },
      status: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options: fn _assigns ->
          [
            {"Pending", :pending},
            {"Approved", :approved},
            {"Rejected", :rejected}
          ]
        end
      },
      creative_id: %{
        module: Backpex.Fields.Text,
        label: "Creative ID",
        readonly: true
      },
      user_id: %{
        module: Backpex.Fields.Text,
        label: "Member ID",
        readonly: true
      },
      message: %{
        module: Backpex.Fields.Textarea,
        label: "Message",
        readonly: true
      }
    ]
  end

  @impl Backpex.LiveResource
  def on_item_updated(socket, %Timesink.Cinema.CreativeClaim{} = claim) do
    claim = Timesink.Repo.preload(claim, [:user, :creative])
    maybe_handle_status_change(claim)
    {socket, :ok}
  end

  defp maybe_handle_status_change(%{status: :approved} = claim) do
    Timesink.Cinema.Creative.update(claim.creative, %{user_id: claim.user_id})
    Timesink.Cinema.Mail.send_creative_claim_approved(claim.user, claim.creative)
  end

  defp maybe_handle_status_change(%{status: :rejected} = claim) do
    Timesink.Cinema.Mail.send_creative_claim_rejected(claim.user, claim.creative)
  end

  defp maybe_handle_status_change(_), do: :noop
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
