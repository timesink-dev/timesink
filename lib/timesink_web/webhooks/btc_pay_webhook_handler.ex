defmodule TimesinkWeb.BtcPayWebhookHandler do
  require Logger
  alias Timesink.Cinema.FilmSubmission

  def handle_event(%{
        "type" => "InvoiceSettled",
        "invoiceId" => invoice_id,
        "metadata" => metadata
      }) do
    Logger.info("BTCPay InvoiceSettled event for invoice #{invoice_id}")

    case FilmSubmission.create(metadata) do
      {:ok, submission} ->
        Logger.info("✅ Film submission created for BTCPay invoice #{invoice_id}")

        TimesinkWeb.Endpoint.broadcast(
          "film_submission",
          "film_submission_completed",
          submission
        )

        :ok

      {:error, reason} ->
        Logger.error("❌ BTCPay submission failed: #{inspect(reason)}")
        :error
    end
  end

  def handle_event(%{
        "type" => "InvoiceCreated",
        "invoiceId" => invoice_id,
        "metadata" => metadata
      }) do
    Logger.info("BTCPay InvoiceCreated for invoice #{invoice_id}")
    Logger.debug("Invoice metadata: #{inspect(metadata)}")

    :ok

    # case BtcPay.fetch_invoice(invoice_id) do
    #   {:ok, invoice} ->
    #     Logger.debug("Fetched invoice data: #{inspect(invoice)}")
    #     :ok

    #   {:error, reason} ->
    #     Logger.warn("Failed to fetch invoice: #{inspect(reason)}")
    #     :error
    # end
  end

  def handle_event(%{"type" => type}) do
    Logger.info("Unhandled BTCPay event type: #{type}")
    :ok
  end

  def handle_event(event) do
    Logger.warning("⚠️ Unrecognized BTCPay event payload: #{inspect(event)}")
    :ok
  end
end
