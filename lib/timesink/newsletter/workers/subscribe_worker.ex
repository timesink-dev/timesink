defmodule Timesink.Newsletter.Workers.SubscribeWorker do
  @moduledoc """
  Background job to subscribe a user to the newsletter via Resend.
  Runs in the :account queue with immediate execution.
  """
  use Oban.Worker, queue: :account

  alias Timesink.Newsletter.Resend

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email}}) do
    case Resend.subscribe(email) do
      {:ok, :subscribed} -> :ok
      {:ok, :already_subscribed} -> :ok
      {:error, _reason} -> :ok
    end
  end
end
