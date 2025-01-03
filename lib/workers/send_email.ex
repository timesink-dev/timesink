defmodule Timesink.Workers.SendEmail do
  use Oban.Worker, queue: :mailer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email_args}}) do
    with email <- Timesink.Mailer.from_map(email_args),
         {:ok, _metadata} <- Timesink.Mailer.deliver(email) do
      :ok
    end
  end
end
