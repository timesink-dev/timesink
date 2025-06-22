defmodule TimesinkWeb.BtcPayController do
  use TimesinkWeb, :controller
  require Logger

  alias Timesink.Cinema.FilmSubmission

  plug :verify_signature

  def webhook(conn, %{"type" => "InvoiceSettled", "invoiceId" => invoice_id}) do
    Logger.info("BTCPay InvoiceSettled event for invoice #{invoice_id}")

    with {:ok, invoice_data} <- Timesink.BtcPay.fetch_invoice(invoice_id),
         %{"metadata" => metadata} <- invoice_data do
      case FilmSubmission.create(metadata) do
        {:ok, _submission} ->
          send_resp(conn, 200, "created")

        {:error, reason} ->
          Logger.error("Create failed: #{inspect(reason)}") && send_resp(conn, 500, "error")
      end
    else
      _ -> send_resp(conn, 400, "bad request")
    end
  end

  def webhook(conn, _params) do
    raw = conn.assigns[:raw_body]

    with {:ok, data} <- Jason.decode(raw) do
      Logger.debug("BTCPay Webhook: #{inspect(data)}")

      case data["type"] do
        "InvoiceSettled" ->
          handle_invoice_settled(conn, data)

        "InvoiceCreated" ->
          handle_invoice_created(conn, data)

        _ ->
          Logger.info("Unhandled BTCPay event type: #{data["type"]}")
          send_resp(conn, 200, "ok")
      end
    else
      {:error, reason} ->
        Logger.error("Failed to parse webhook body: #{inspect(reason)}")
        send_resp(conn, 400, "bad request")
    end
  end

  defp handle_invoice_settled(conn, %{"invoiceId" => invoice_id}) do
    Logger.info("BTCPay InvoiceSettled event for invoice #{invoice_id}")

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
      "stripe_id" => nil,
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

        send_resp(conn, 200, "created")

      {:error, reason} ->
        Logger.error("Film submission creation failed: #{inspect(reason)}")
        send_resp(conn, 500, "error")
    end
  end

  defp handle_invoice_created(conn, %{"invoiceId" => invoice_id}) do
    Logger.info("BTCPay InvoiceCreated event for invoice #{invoice_id}")

    with {:ok, invoice_data} <- Timesink.BtcPay.fetch_invoice(invoice_id) do
      # Handle the created invoice as needed
      Logger.debug("Invoice created: #{inspect(invoice_data)}")
      send_resp(conn, 200, "ok")
    else
      _ -> send_resp(conn, 400, "bad request")
    end
  end

  # Optional: BTCPay signs webhooks — you can validate with their signature
  defp verify_signature(conn, _opts) do
    raw_body = conn.assigns[:raw_body] || conn.params["raw_body"]

    IO.inspect(raw_body, label: "Raw Body for BTCPay Signature Verification")

    config = btc_pay_config()
    webhook_secret = config.webhook_secret

    # {:ok, raw_body, conn} = Plug.Conn.read_body(conn)

    [full_signature] = Plug.Conn.get_req_header(conn, "btcpay-sig")

    "sha256=" <> received_sig = full_signature

    expected_sig =
      :crypto.mac(:hmac, :sha256, webhook_secret, raw_body)
      |> Base.encode16(case: :lower)

    if secure_compare(expected_sig, received_sig) do
      # Re-assign the raw body for downstream controller usage
      conn
      |> assign(:raw_body, raw_body)
      |> Plug.Conn.assign(:json_body, Jason.decode!(raw_body))
    else
      conn
      |> send_resp(401, "Invalid BTCPay signature")
      |> halt()
    end
  end

  # Avoid timing attacks
  defp secure_compare(a, b) when byte_size(a) == byte_size(b),
    do: Plug.Crypto.secure_compare(a, b)

  defp secure_compare(_, _), do: false

  defp btc_pay_config, do: Application.fetch_env!(:timesink, :btc_pay) |> Enum.into(%{})
end
