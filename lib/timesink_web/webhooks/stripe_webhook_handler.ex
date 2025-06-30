defmodule TimesinkWeb.StripeWebhookHandler do
  require Logger
  alias Timesink.Cinema
  alias Timesink.Cinema.FilmSubmission

  def handle_event(%{"type" => "payment_intent.created"} = event) do
    IO.inspect(event, label: "🟡 PAYMENT INTENT CREATED")
    :ok
  end

  def handle_event(%{"type" => "payment_intent.succeeded", "data" => %{"object" => pi}}) do
    Logger.info("Stripe payment succeeded: #{pi["id"]}")

    # Replace with actual invoice ID extraction logic
    invoice_id = "test_invoice_id"

    # # Extract metadata
    # user_id = pi["metadata"]["user_id"]
    # email = pi["receipt_email"] || pi["metadata"]["contact_email"]

    # hardcoded metadata for testing purposes
    # in a real application, you would extract this from the invoice data
    metadata = %{
      "title" => "The Luminous Gaze",
      "year" => 2024,
      "duration_min" => 14,
      "synopsis" => "An evocative short film exploring memory, light, and grief.",
      "video_url" => "https://vimeo.com/123456789",
      "video_pw" => "secretpass",
      "contact_name" => "Léa Moreau",
      "contact_email" => "lea.moreau@example.com",
      # required
      "status_review" => "received",
      "review_notes" => nil,
      "payment_id" => invoice_id,
      # or a valid UUID if available
      "submitted_by_id" => nil
    }

    case Timesink.Cinema.FilmSubmission.create(metadata) do
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
        # send_resp(conn, 500, "error")
    end
  end

  #   send_resp(conn, 500, "")
  # end

  # Catch-all fallback
  def handle_event(%{"type" => type}) do
    Logger.info("Unhandled Stripe event type: #{type}")
    :ok
  end

  def handle_event(%{"type" => "checkout.session.completed"} = event) do
    IO.inspect(event, label: "✅ CHECKOUT SESSION COMPLETED")
    :ok
  end

  def handle_event(%{"type" => "invoice.paid"} = event) do
    IO.inspect(event, label: "💰 INVOICE PAID")
    :ok
  end

  def handle_event(event) do
    IO.inspect(event, label: "⚠️ UNKNOWN EVENT TYPE")
    :ok
  end
end
