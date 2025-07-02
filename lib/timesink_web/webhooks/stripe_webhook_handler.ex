defmodule TimesinkWeb.StripeWebhookHandler do
  require Logger
  alias Timesink.Cinema.FilmSubmission

  def handle_event(%{"type" => "payment_intent.created"}) do
    :ok
  end

  def handle_event(%{"type" => "payment_intent.succeeded", "data" => %{"object" => pi}}) do
    invoice_id = pi["id"]

    metadata =
      (pi["metadata"] || %{})
      |> Map.merge(%{
        "payment_id" => invoice_id
      })

    case FilmSubmission.create(metadata) do
      {:ok, submission} ->
        Logger.info("Film submission created for invoice #{invoice_id}")

        TimesinkWeb.Endpoint.broadcast(
          "film_submission",
          "film_submission_completed",
          submission
        )

      # send_resp(conn, 200, "created")

      {:error, reason} ->
        Logger.error("Film submission creation failed: #{inspect(reason)}")
    end
  end

  def handle_event(%{"type" => "checkout.session.completed"} = event) do
    IO.inspect(event, label: "✅ CHECKOUT SESSION COMPLETED")
    :ok
  end

  def handle_event(%{"type" => "invoice.paid"} = event) do
    IO.inspect(event, label: "💰 INVOICE PAID")
    :ok
  end

  # Catch-all fallback
  def handle_event(%{"type" => type}) do
    Logger.info("Unhandled Stripe event type: #{type}")
    :ok
  end

  def handle_event(event) do
    IO.inspect(event, label: "⚠️ UNKNOWN EVENT TYPE")
    :ok
  end
end
