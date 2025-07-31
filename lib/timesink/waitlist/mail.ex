defmodule Timesink.Waitlist.Mail do
  use Timesink.Mailer

  defp base_url do
    Application.fetch_env!(:timesink, :base_url)
  end

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

  def send_invite_code(to_email, first_name, code) do
    send_mail(
      to_email,
      "You're invited to join!",
      """
      Hey #{first_name},

      You're invited to join! Click the link below to create your account:

      #{base_url()}/invite/#{code}
      """
    )
  end
end
