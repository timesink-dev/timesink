defmodule Timesink.Mailer do
  use Swoosh.Mailer, otp_app: :timesink

  # inspired by:
  # https://peterullrich.com/sending-emails-with-swoosh-and-oban

  @doc """
  Converts an Email struct to a map (intended for args passed into Oban workers).
  """
  def to_map(%Swoosh.Email{} = email) do
    %{
      "to" => contact_to_map(email.to),
      "from" => contact_to_map(email.from),
      "subject" => email.subject,
      "text_body" => email.text_body
    }
  end

  @doc """
  Converts a map to an Email struct (for Swoosh).
  """
  @spec from_map(map()) :: Swoosh.Email.t()
  def from_map(args) do
    %{
      "to" => to,
      "from" => from,
      "subject" => subject,
      "text_body" => text_body
    } = args

    opts = [
      to: map_to_contact(to),
      from: map_to_contact(from),
      subject: subject,
      text_body: text_body
      # Add a text_html if needed.
    ]

    Swoosh.Email.new(opts)
  end

  defp contact_to_map(info) when is_list(info) do
    Enum.map(info, &contact_to_map/1)
  end

  defp contact_to_map({name, email}) do
    %{"name" => name, "email" => email}
  end

  defp map_to_contact(info) when is_list(info) do
    Enum.map(info, &map_to_contact/1)
  end

  defp map_to_contact(%{"name" => name, "email" => email}) do
    {name, email}
  end

  defmacro __using__(_opts) do
    quote do
      import Swoosh.Email
      alias Timesink.Workers.SendMail

      def send_mail(recipient, subject, body) do
        email =
          new()
          |> to(recipient)
          |> from({"TimeSink Presents", "hello@timesinkpresents.com"})
          |> subject(subject)
          |> text_body(body)

        with email_map <- Timesink.Mailer.to_map(email),
             {:ok, _job} <- enqueue_worker(email_map) do
          {:ok, email}
        end
      end

      defp enqueue_worker(email) do
        %{email: email}
        |> SendMail.new()
        |> Oban.insert()
      end
    end
  end
end
