defmodule Timesink.EmailNotifications do
  import Swoosh.Email
  alias Timesink.Mailer

  def send_waitlist_confirmation(to_email) do
    new()
    |> to(to_email)
    |> from({"TimeSink Presents", "noreply@timesinkpresents.com"})
    |> subject("Welcome to TimeSink!")
    |> html_body("<h1>Welcome!</h1><p>Thank you for joining our waitlist.</p>")
    |> text_body("Welcome! Thank you for joining our waitlist.")
    |> Mailer.deliver()
  end
end
