defmodule Timesink.Cinema.CreativeClaims do
  @moduledoc """
  Handles the creative claim flow — members claiming their creative profile.
  """

  alias Timesink.Cinema.{Creative, CreativeClaim}
  alias Timesink.Cinema.Mail
  alias Timesink.Repo
  import Ecto.Query

  @doc """
  Submits a claim from a user for a creative. Sends an admin notification email.
  Returns an error if a claim already exists for this user/creative pair.
  """
  @spec submit_claim(
          user :: Timesink.Account.User.t(),
          creative_id :: Ecto.UUID.t(),
          message :: String.t() | nil
        ) ::
          {:ok, CreativeClaim.t()} | {:error, Ecto.Changeset.t()}
  def submit_claim(user, creative_id, message \\ nil) do
    params = %{user_id: user.id, creative_id: creative_id, message: message}

    with {:ok, claim} <- CreativeClaim.create(params) do
      claim = Repo.preload(claim, :creative)
      Mail.send_creative_claim_notification(user, claim.creative)
      {:ok, claim}
    end
  end

  @doc """
  Approves a pending claim. Sets creative.user_id to the claimant and marks the claim approved.
  Rejects any other pending claims for the same creative.
  Sends an approval email to the user.
  """
  @spec approve_claim(CreativeClaim.t()) :: {:ok, CreativeClaim.t()} | {:error, any()}
  def approve_claim(%CreativeClaim{} = claim) do
    claim = Repo.preload(claim, [:user, :creative])

    Repo.transaction(fn ->
      with {:ok, _creative} <- Creative.update(claim.creative, %{user_id: claim.user_id}),
           {:ok, approved_claim} <- CreativeClaim.update(claim, %{status: :approved}) do
        # Reject all other pending claims for this creative
        from(c in CreativeClaim,
          where: c.creative_id == ^claim.creative_id,
          where: c.id != ^claim.id,
          where: c.status == :pending
        )
        |> Repo.update_all(set: [status: :rejected])

        Mail.send_creative_claim_approved(claim.user, claim.creative)
        approved_claim
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Rejects a pending claim. Sends a rejection email to the user.
  """
  @spec reject_claim(CreativeClaim.t()) :: {:ok, CreativeClaim.t()} | {:error, any()}
  def reject_claim(%CreativeClaim{} = claim) do
    claim = Repo.preload(claim, [:user, :creative])

    with {:ok, rejected_claim} <-
           CreativeClaim.update(claim, CreativeClaim.status_changeset(claim, :rejected)) do
      Mail.send_creative_claim_rejected(claim.user, claim.creative)
      {:ok, rejected_claim}
    end
  end

  @doc """
  Lists all pending claims, preloaded with user and creative.
  """
  def list_pending_claims do
    CreativeClaim
    |> where([c], c.status == :pending)
    |> order_by([c], asc: c.inserted_at)
    |> preload([:user, :creative])
    |> Repo.all()
  end
end
