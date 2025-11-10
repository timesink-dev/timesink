defmodule Timesink.Workers.Account.CleanupExpiredEmailVerificationJobTest do
  use Timesink.DataCase, async: true
  use Oban.Testing, repo: Timesink.Repo

  import Timesink.Factory

  alias Timesink.Workers.Account.CleanupExpiredEmailVerificationJob
  alias Timesink.Token
  alias Timesink.Account.User

  describe "perform/1" do
    test "clears unverified_email for users with expired email_verification tokens" do
      # Create a user with an unverified email
      new_email = "newemail@example.com"
      user = insert(:user, unverified_email: new_email)

      # Create an expired email verification token
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      token =
        insert(:token,
          kind: :email_verification,
          user_id: user.id,
          email: new_email,
          expires_at: expired_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert the job found and processed the token
      assert result.success == 1
      assert result.errors == 0

      # Verify the user's unverified_email was cleared
      updated_user = User.get!(user.id)
      assert updated_user.unverified_email == nil

      # Verify the token was invalidated
      updated_token = Token.get!(token.id)
      assert updated_token.status == :invalid
    end

    test "does not affect users with valid (non-expired) email_verification tokens" do
      # Create a user with an unverified email
      new_email = "newemail@example.com"
      user = insert(:user, unverified_email: new_email)

      # Create a non-expired email verification token
      expires_at = DateTime.utc_now() |> DateTime.add(1, :hour)

      token =
        insert(:token,
          kind: :email_verification,
          user_id: user.id,
          email: new_email,
          expires_at: expires_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert no tokens were processed
      assert result.success == 0
      assert result.errors == 0

      # Verify the user's unverified_email was not cleared
      updated_user = User.get!(user.id)
      assert updated_user.unverified_email == new_email

      # Verify the token was not invalidated
      updated_token = Token.get!(token.id)
      assert updated_token.status == :valid
    end

    test "processes multiple expired tokens" do
      # Create multiple users with expired tokens
      user1 = insert(:user, unverified_email: "user1@example.com")
      user2 = insert(:user, unverified_email: "user2@example.com")

      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      token1 =
        insert(:token,
          kind: :email_verification,
          user_id: user1.id,
          email: user1.unverified_email,
          expires_at: expired_at,
          status: :valid
        )

      token2 =
        insert(:token,
          kind: :email_verification,
          user_id: user2.id,
          email: user2.unverified_email,
          expires_at: expired_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert both tokens were processed
      assert result.success == 2
      assert result.errors == 0

      # Verify both users' unverified_email fields were cleared
      updated_user1 = User.get!(user1.id)
      assert updated_user1.unverified_email == nil

      updated_user2 = User.get!(user2.id)
      assert updated_user2.unverified_email == nil

      # Verify both tokens were invalidated
      updated_token1 = Token.get!(token1.id)
      assert updated_token1.status == :invalid

      updated_token2 = Token.get!(token2.id)
      assert updated_token2.status == :invalid
    end

    test "handles tokens where user has no unverified_email (token only invalidation)" do
      # Create a user without an unverified email
      user = insert(:user, unverified_email: nil)

      # Create an expired token (edge case: token exists but user cleared unverified_email)
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      token =
        insert(:token,
          kind: :email_verification,
          user_id: user.id,
          email: "oldemail@example.com",
          expires_at: expired_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert the token was still processed
      assert result.success == 1
      assert result.errors == 0

      # Verify the user's unverified_email is still nil
      updated_user = User.get!(user.id)
      assert updated_user.unverified_email == nil

      # Verify the token was invalidated
      updated_token = Token.get!(token.id)
      assert updated_token.status == :invalid
    end

    test "ignores email_verification tokens without user_id" do
      # Create an expired email verification token without user_id (signup flow)
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      _token =
        insert(:token,
          kind: :email_verification,
          user_id: nil,
          email: "signup@example.com",
          expires_at: expired_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert no tokens were processed (no user_id)
      assert result.success == 0
      assert result.errors == 0
    end

    test "ignores expired tokens that are already invalid" do
      # Create a user with an unverified email
      new_email = "newemail@example.com"
      user = insert(:user, unverified_email: new_email)

      # Create an expired token that's already invalid
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      _token =
        insert(:token,
          kind: :email_verification,
          user_id: user.id,
          email: new_email,
          expires_at: expired_at,
          status: :invalid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert no tokens were processed (already invalid)
      assert result.success == 0
      assert result.errors == 0

      # Verify the user's unverified_email was not cleared
      updated_user = User.get!(user.id)
      assert updated_user.unverified_email == new_email
    end

    test "ignores expired tokens of other kinds (password_reset, invite)" do
      # Create expired tokens of other kinds
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      _password_reset_token =
        insert(:token,
          kind: :password_reset,
          email: "reset@example.com",
          expires_at: expired_at,
          status: :valid
        )

      _invite_token =
        insert(:token,
          kind: :invite,
          email: "invite@example.com",
          expires_at: expired_at,
          status: :valid
        )

      # Run the job
      assert {:ok, result} = perform_job(CleanupExpiredEmailVerificationJob, %{})

      # Assert no tokens were processed (wrong kind)
      assert result.success == 0
      assert result.errors == 0
    end
  end
end
