defmodule TimesinkWeb.BtcPayController do
  use TimesinkWeb, :controller
  require Logger

  alias TimesinkWeb.BtcPayWebhookHandler

  plug :verify_signature

  def webhook(conn, _params) do
    raw = conn.assigns[:raw_body]

    with {:ok, data} <- Jason.decode(raw) do
      Logger.debug("BTCPay Webhook: #{inspect(data)}")
      BtcPayWebhookHandler.handle_event(data)
      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.error("Failed to parse webhook: #{inspect(reason)}")
        send_resp(conn, 400, "bad request")
    end
  end

  defp verify_signature(conn, _opts) do
    raw_body = conn.assigns[:raw_body] || conn.params["raw_body"]
    config = btc_pay_config()
    webhook_secret = config.webhook_secret

    [full_signature] = Plug.Conn.get_req_header(conn, "btcpay-sig")
    "sha256=" <> received_sig = full_signature

    expected_sig =
      :crypto.mac(:hmac, :sha256, webhook_secret, raw_body)
      |> Base.encode16(case: :lower)

    if Plug.Crypto.secure_compare(expected_sig, received_sig) do
      assign(conn, :raw_body, raw_body)
    else
      conn |> send_resp(401, "Invalid BTCPay signature") |> halt()
    end
  end

  defp btc_pay_config, do: Application.fetch_env!(:timesink, :btc_pay) |> Enum.into(%{})
end
