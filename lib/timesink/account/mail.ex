defmodule Timesink.Account.Mail do
  use Timesink.Mailer

  def send_email_verification(email, code) do
    send_mail(
      email,
      "Verify your email address",
      """
      Please verify your email address by entering the following code on the verification page:

      #{code}
      """
    )
  end

  @doc """
  Sends an email change verification code to the new email address.
  """
  def send_email_change_verification(email, code) do
    send_mail(
      email,
      "Verify your new email address",
      """
      Hi,

      You requested to change your email address for your TimeSink account.

      Please verify your new email address by entering the following code:

      #{code}

      This code will expire in 15 minutes.

      If you didn't request this change, you can safely ignore this email.

      — The TimeSink Team
      """
    )
  end

  @doc """
  Sends a password reset email with a link to set a new password.
  """
  def send_password_reset(email, url) do
    send_mail(
      email,
      "Reset your TimeSink password",
      """
      Hi,

      We received a request to reset the password for your TimeSink account.

      Click the link below to choose a new password (valid for the next hour):

      #{url}

      If you didn't request this, you can safely ignore this email and your password will remain unchanged.

      — The TimeSink Team
      """
    )
  end
end
