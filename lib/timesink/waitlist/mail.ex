defmodule Timesink.Waitlist.Mail do
  use Timesink.Mailer

  def send_waitlist_confirmation(to_email, first_name) do
    subject = "Welcome to TimeSink: you're on the waitlist"

    body = """
    Hi #{first_name},

    Thanks for signing up for early access to TimeSink. You’re officially on the waitlist.

    We introduce new members gradually as we shape the community and programming, and we’ll email you as soon as your spot opens.

    In the meantime, you can get a feel for what we’re building at our blog on our Substack, where we share programming notes, editorials, critiques, and film analysis:
    https://timesinkpresents.substack.com/

    If you have any questions, just reply to this email.

    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  def send_invite_code(to_email, first_name, code) do
    subject = "Your invitation to join TimeSink"

    body = """
    Hi #{first_name},

    Great news! Your spot is ready. You’re now officially invited to join TimeSink.

    Click the link below to create your account and step inside:
    #{base_url()}/invite/#{code}

    We’re glad to have you with us.

    See you around,

    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  defp base_url do
    Application.fetch_env!(:timesink, :base_url)
  end
end
