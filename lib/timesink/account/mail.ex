defmodule Timesink.Accounts.Mail do
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
end
