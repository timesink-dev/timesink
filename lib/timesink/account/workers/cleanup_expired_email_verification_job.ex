defmodule Timesink.Workers.Account.CleanupExpiredEmailVerificationJob do
  @moduledoc """
  Cron job that cleans up expired email verification tokens for email change requests.

  Runs daily to find:
  - Email verification tokens that have expired
  - Associated users who have a pending unverified_email

  For each expired token, clears the user's unverified_email field back to nil,
  since the email change verification link has expired.
  """
  use Oban.Worker, queue: :mailer, max_attempts: 3

  alias Timesink.Token
  alias Timesink.Account.User
  alias Timesink.Repo

  import Ecto.Query

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info(
      "[CleanupExpiredEmailVerificationJob] Starting cleanup of expired email verification tokens"
    )

    # Find expired email_verification tokens that are associated with users
    expired_tokens =
      from(t in Token,
        where: t.kind == :email_verification,
        where: t.status == :valid,
        where: not is_nil(t.user_id),
        where: t.expires_at < ^DateTime.utc_now()
      )
      |> Repo.all()

    Logger.info(
      "[CleanupExpiredEmailVerificationJob] Found #{length(expired_tokens)} expired email verification tokens"
    )

    # Process each expired token
    results =
      Enum.map(expired_tokens, fn token ->
        process_expired_token(token)
      end)

    success_count = Enum.count(results, fn r -> match?({:ok, _}, r) end)
    error_count = Enum.count(results, fn r -> match?({:error, _}, r) end)

    Logger.info(
      "[CleanupExpiredEmailVerificationJob] Cleanup complete. Success: #{success_count}, Errors: #{error_count}"
    )

    {:ok, %{success: success_count, errors: error_count}}
  end

  @spec process_expired_token(Token.t()) :: {:ok, User.t()} | {:error, term()}
  defp process_expired_token(token) do
    with {:ok, user} <- User.get(token.user_id),
         true <- user.unverified_email != nil do
      Logger.info(
        "[CleanupExpiredEmailVerificationJob] Clearing unverified_email for user #{user.id}"
      )

      # Clear the unverified_email field using email_only_changeset
      case User.update(user, %{"unverified_email" => nil},
             changeset: &User.email_only_changeset/2
           ) do
        {:ok, updated_user} ->
          # Invalidate the token as well
          Token.invalidate_token(token)
          {:ok, updated_user}

        {:error, reason} ->
          Logger.error(
            "[CleanupExpiredEmailVerificationJob] Failed to clear unverified_email for user #{user.id}: #{inspect(reason)}"
          )

          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warning(
          "[CleanupExpiredEmailVerificationJob] User not found for token #{token.id}: #{inspect(reason)}"
        )

        {:error, reason}

      false ->
        # User doesn't have unverified_email, just invalidate the token
        Token.invalidate_token(token)
        {:ok, :no_action_needed}
    end
  end
end
