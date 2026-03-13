defmodule Timesink.Cinema.CreativeClaimsTest do
  use Timesink.DataCase, async: true

  import Timesink.Factory

  alias Timesink.Cinema.{Creative, CreativeClaim, CreativeClaims}
  alias Timesink.Repo

  describe "submit_claim/3" do
    test "creates a pending claim" do
      user = insert(:user)
      creative = insert(:creative)

      assert {:ok, claim} = CreativeClaims.submit_claim(user, creative.id)

      assert claim.user_id == user.id
      assert claim.creative_id == creative.id
      assert claim.status == :pending
      assert claim.message == nil
    end

    test "stores optional message on the claim" do
      user = insert(:user)
      creative = insert(:creative)

      assert {:ok, claim} = CreativeClaims.submit_claim(user, creative.id, "I made this film")

      assert claim.message == "I made this film"
    end

    test "returns error when claim already exists for same user/creative pair" do
      user = insert(:user)
      creative = insert(:creative)

      assert {:ok, _} = CreativeClaims.submit_claim(user, creative.id)
      assert {:error, changeset} = CreativeClaims.submit_claim(user, creative.id)

      errors = errors_on(changeset)
      assert errors[:user_id] != [] or errors[:creative_id] != []
    end

    test "allows different users to claim the same creative" do
      user1 = insert(:user)
      user2 = insert(:user)
      creative = insert(:creative)

      assert {:ok, _} = CreativeClaims.submit_claim(user1, creative.id)
      assert {:ok, _} = CreativeClaims.submit_claim(user2, creative.id)
    end

    test "allows same user to claim different creatives" do
      user = insert(:user)
      creative1 = insert(:creative)
      creative2 = insert(:creative)

      assert {:ok, _} = CreativeClaims.submit_claim(user, creative1.id)
      assert {:ok, _} = CreativeClaims.submit_claim(user, creative2.id)
    end
  end

  describe "approve_claim/1" do
    test "sets creative.user_id to the claimant and marks claim approved" do
      user = insert(:user)
      creative = insert(:creative)
      {:ok, claim} = CreativeClaims.submit_claim(user, creative.id)

      assert {:ok, approved_claim} = CreativeClaims.approve_claim(claim)

      assert approved_claim.status == :approved

      reloaded_creative = Repo.get!(Creative, creative.id)
      assert reloaded_creative.user_id == user.id
    end

    test "rejects all other pending claims for the same creative" do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)
      creative = insert(:creative)

      {:ok, claim1} = CreativeClaims.submit_claim(user1, creative.id)
      {:ok, claim2} = CreativeClaims.submit_claim(user2, creative.id)
      {:ok, claim3} = CreativeClaims.submit_claim(user3, creative.id)

      assert {:ok, _} = CreativeClaims.approve_claim(claim1)

      assert Repo.get!(CreativeClaim, claim1.id).status == :approved
      assert Repo.get!(CreativeClaim, claim2.id).status == :rejected
      assert Repo.get!(CreativeClaim, claim3.id).status == :rejected
    end

    test "links creative to user so user has_one :creative association" do
      user = insert(:user)
      creative = insert(:creative)
      {:ok, claim} = CreativeClaims.submit_claim(user, creative.id)

      assert {:ok, _} = CreativeClaims.approve_claim(claim)

      reloaded_user = Repo.preload(Repo.get!(Timesink.Account.User, user.id), :creative)
      assert reloaded_user.creative.id == creative.id
    end
  end

  describe "reject_claim/1" do
    test "marks claim as rejected" do
      user = insert(:user)
      creative = insert(:creative)
      {:ok, claim} = CreativeClaims.submit_claim(user, creative.id)

      assert {:ok, rejected_claim} = CreativeClaims.reject_claim(claim)

      assert rejected_claim.status == :rejected
    end

    test "does not set creative.user_id" do
      user = insert(:user)
      creative = insert(:creative)
      {:ok, claim} = CreativeClaims.submit_claim(user, creative.id)

      assert {:ok, _} = CreativeClaims.reject_claim(claim)

      reloaded_creative = Repo.get!(Creative, creative.id)
      assert reloaded_creative.user_id == nil
    end
  end

  describe "list_pending_claims/0" do
    test "returns only pending claims, ordered by insertion time" do
      user1 = insert(:user)
      user2 = insert(:user)
      creative1 = insert(:creative)
      creative2 = insert(:creative)

      {:ok, claim1} = CreativeClaims.submit_claim(user1, creative1.id)
      {:ok, claim2} = CreativeClaims.submit_claim(user2, creative2.id)

      # approve one so it's no longer pending
      CreativeClaims.approve_claim(claim1)

      pending = CreativeClaims.list_pending_claims()

      ids = Enum.map(pending, & &1.id)
      assert claim2.id in ids
      refute claim1.id in ids
    end

    test "preloads user and creative associations" do
      user = insert(:user)
      creative = insert(:creative)
      {:ok, _} = CreativeClaims.submit_claim(user, creative.id)

      [claim] = CreativeClaims.list_pending_claims()

      assert %Timesink.Account.User{} = claim.user
      assert %Creative{} = claim.creative
    end
  end
end
