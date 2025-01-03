defmodule Timesink.EmailNotifications do
  import Swoosh.Email
  alias Timesink.Mailer
  alias Timesink.Workers

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"TimeSink Presents", "hello@timesinkpresents.com"})
      |> subject(subject)
      |> text_body(body)

    with email_map <- Mailer.to_map(email),
         {:ok, _job} <- enqueue_worker(email_map) do
      {:ok, email}
    end
  end

  defp enqueue_worker(email) do
    %{email: email}
    |> Workers.SendEmail.new()
    |> Oban.insert()
  end

  def send_waitlist_confirmation(to_email) do
    deliver(
      to_email,
      "You're on the waitlist!",
      """
      You're on the waitlist! We'll let you know when you are the next one in line to join.
      """
    )
  end
end
