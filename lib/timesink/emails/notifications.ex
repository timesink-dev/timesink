defmodule Timesink.EmailNotifications do
  import Swoosh.Email
  alias Timesink.Mailer
  alias Timesink.Workers.SendEmail

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Your Name", "your-email.com"})
      |> subject(subject)
      |> text_body(body)

    with email_map <- Mailer.to_map(email),
         {:ok, _job} <- enqueue_worker(email_map) do
      {:ok, email}
    end
  end

  defp enqueue_worker(email) do
    %{email: email}
    |> SendEmail.new()
    |> Oban.insert()
  end

  def send_waitlist_confirmation(to_email) do
    deliver(
      to_email,
      "You're on the waitlist!",
      """
      You're on the waitlist! We'll let you know when you can join.
      """
    )
  end
end
