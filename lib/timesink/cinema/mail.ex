defmodule Timesink.Cinema.Mail do
  use Timesink.Mailer

  def send_film_submission_completion_notification(to_email, contact_name, submission) do
    send_mail(
      to_email,
      "Film Submission Received",
      """
      Hi #{contact_name},

      Your film submission #{submission.title} has been received! We'll review it and get back to you soon.

      In the meantime, please feel free to check the status of your submissions in your account film submissions dashboard and if you have any questions, feel free to reach out to us at hello@timesinkpresents.com.

      Thanks for your submission!
      """
    )
  end

  def send_film_status_update(submission, new_status) do
    send_mail(
      submission.contact_email,
      "Film Submission Status Update",
      """
      Hi #{submission.contact_name},

      #{build_status_message(submission, new_status)}

      If you have any questions or need further assistance, feel free to reach out to us at hello@timesinkpresents.com.

      Thanks for your patience!
      """
    )
  end

  defp format_status(:received), do: "Received 📨"

  defp format_status(:under_review),
    do: "Under Review 🔍 as we are currently watching your submission."

  defp format_status(:accepted), do: "Accepted ✅"
  defp format_status(:rejected), do: "Rejected"

  def build_status_message(submission, new_status) do
    case new_status do
      :accepted ->
        "Congratulations! Your film submission for <i>#{submission.title}</i> has been accepted ✅ and will be featured in an upcoming showcase right here on TimeSink! We'll be in touch with further details soon."

      :rejected ->
        "Unfortunately, your film submission for <i>#{submission.title}</i> has not been accepted at this time. We appreciate your effort and encourage you to submit again in the future."

      _ ->
        "Your film submission for <i>#{submission.title}</i> status has been updated to #{format_status(new_status)}

        We'll keep you posted on any further updates."
    end
  end
end
