defmodule Timesink.Waitlist.Mail do
  use Timesink.Mailer

  def send_waitlist_confirmation(to_email, first_name) do
    send_mail(
      to_email,
      "You're on the waitlist!",
      """
      Hey #{first_name},

      You're on the waitlist! We'll let you know when you are the next one in line to join.
      """
    )
  end
end
