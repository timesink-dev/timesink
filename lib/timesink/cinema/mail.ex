defmodule Timesink.Cinema.Mail do
  use Timesink.Mailer

  def send_film_submission_completion_notification(to_email, contact_name, submission) do
    subject = "Your film submission has been received"

    body = """
    Hi #{contact_name},

    We’ve received your film submission #{submission.title}. Our team will review it carefully and get back to you soon.

    You can check the status of your submission anytime from your film submissions dashboard at #{base_url()}/me/film-submissions.

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

  def send_creative_claim_notification(user, creative) do
    subject = "Creative claim submitted: #{creative.first_name} #{creative.last_name}"

    body = """
    A TimeSink member has submitted a claim for a creative profile.

    Member: #{user.first_name} #{user.last_name} (#{user.email})
    Creative: #{creative.first_name} #{creative.last_name}

    Review and approve or reject this claim in the admin panel:
    #{base_url()}/admin/creative-claims
    """

    send_mail("hello@timesinkpresents.com", subject, body)
  end

  def send_creative_claim_approved(user, creative) do
    subject = "Your TimeSink Creative profile has been verified"

    body = """
    Hi #{user.first_name},

    Great news — your claim for the creative profile "#{creative.first_name} #{creative.last_name}" has been approved.

    Your TimeSink profile now reflects your status as a verified creative. Your name will appear as a link in film credits where your work is listed.

    See you in the theater,
    The TimeSink Team
    """

    send_mail(user.email, subject, body)
  end

  def send_creative_claim_rejected(user, creative) do
    subject = "Update on your TimeSink Creative claim"

    body = """
    Hi #{user.first_name},

    Thank you for submitting a claim for the creative profile "#{creative.first_name} #{creative.last_name}."

    After review, we were unable to verify this claim at this time. If you believe this is a mistake or have additional information to share, please reply to this email.

    The TimeSink Team
    """

    send_mail(user.email, subject, body)
  end

  defp base_url do
    Application.fetch_env!(:timesink, :base_url)
  end
end
