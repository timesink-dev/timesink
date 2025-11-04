defmodule Timesink.Newsletter.Mail do
  use Timesink.Mailer

  @moduledoc """
  Handles outgoing emails related to newsletter signups.
  """

  @doc """
  Sends a confirmation email to a new newsletter subscriber with a verification link.
  """
  def send_newsletter_confirmation(to_email, token) do
    subject = "Confirm your subscription to TimeSink Presents"

    body = """
    Hi there,

    Thanks for signing up for the TimeSink newsletter — we’re thrilled to have you on board.

    To confirm your subscription, please click the link below:
    #{confirm_url(token)}

    This step helps us make sure it’s really you and keeps our list free of spam and noise.

    Once confirmed, you’ll start receiving updates about new screenings, live events, and editorial notes — all hand-curated by the TimeSink team.

    If you didn’t request this, you can safely ignore this email.

    See you at the next screening,
    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  @spec send_newsletter_welcome(any()) :: {:error, any()} | {:ok, Swoosh.Email.t()}
  @doc """
  Sends a simple welcome email once the user confirms their newsletter subscription.
  """
  def send_newsletter_welcome(to_email) do
    subject = "Welcome to TimeSink Presents"

    body = """
    Hi there,

    You’re officially subscribed to TimeSink Presents.

    Expect occasional dispatches featuring upcoming films, live chat sessions, retrospectives, and behind-the-scenes notes from our curators.

    No noise — just cinema, conversation, and discovery.

    Stay tuned,
    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  defp confirm_url(token) do
    base = Application.fetch_env!(:timesink, :base_url)
    "#{base}/newsletter/confirm/#{token}"
  end
end
