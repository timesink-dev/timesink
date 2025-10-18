defmodule Timesink.Cinema.Mail do
  use Timesink.Mailer

  def send_film_submission_completion_notification(to_email, contact_name, submission) do
    subject = "Your film submission has been received"

    body = """
    Hi #{contact_name},

    We’ve received your film submission, "#{submission.title}." Our team will review it carefully and get back to you soon.

    You can check the status of your submission anytime from your film submissions dashboard.
    If you have any questions, feel free to reach out at hello@timesinkpresents.com.

    Thank you for sharing your work with TimeSink.
    """

    send_mail(to_email, subject, body)
  end

  def send_film_status_update(submission, new_status) do
    subject = "Update on your film submission"

    body = """
    Hi #{submission.contact_name},

    #{build_status_message(submission, new_status)}

    If you have any questions, you can always reach us at hello@timesinkpresents.com.

    The TimeSink Team
    """

    send_mail(submission.contact_email, subject, body)
  end

  defp format_status(:received), do: "received"
  defp format_status(:under_review), do: "under review"
  defp format_status(:accepted), do: "accepted"
  defp format_status(:rejected), do: "not accepted"

  def build_status_message(submission, new_status) do
    title = "\"#{submission.title}\""

    case new_status do
      :accepted ->
        "Good news — your film #{title} has been accepted and will be featured in an upcoming showcase on TimeSink. We’ll be in touch soon with further details."

      :rejected ->
        "We wanted to let you know that your film #{title} was not selected this time. We truly appreciate your submission and encourage you to share future work with us."

      :under_review ->
        "Your film #{title} is currently under review. We’ll notify you as soon as a decision is made."

      _ ->
        "The status of your film #{title} has been updated to #{format_status(new_status)}. We’ll keep you informed as things progress."
    end
  end
end
