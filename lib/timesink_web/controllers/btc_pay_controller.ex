defmodule TimesinkWeb.BtcPayController do
  use TimesinkWeb, :controller
  require Logger

  alias Timesink.Cinema.FilmSubmission

  plug :verify_signature

  def webhook(conn, %{"type" => "InvoiceSettled", "invoiceId" => invoice_id}) do
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
    Logger.info("Unhandled BTCPay event")
    send_resp(conn, 200, "ok")
  end

  # Optional: BTCPay signs webhooks — you can validate with their signature
  defp verify_signature(conn, _opts) do
    # or Application.get_env()
    secret = System.get_env("BTC_PAY_WEBHOOK_SECRET")

    {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
    signature = Plug.Conn.get_req_header(conn, "btcpay-sig") |> List.first()

    expected_sig =
      :crypto.mac(:hmac, :sha256, secret, raw_body)
      |> Base.encode16(case: :lower)

    if secure_compare(expected_sig, signature) do
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
end
