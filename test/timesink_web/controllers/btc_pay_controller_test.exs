defmodule TimesinkWeb.BtcPayControllerTest do
  use TimesinkWeb.ConnCase
  import Timesink.Factory
  alias Timesink.Cinema.FilmSubmission

  # Replace with actual HMAC if needed
  @valid_sig "validsig123"

  defp signed_post(conn, body) do
    webhook_secret = Application.fetch_env!(:timesink, :btc_pay)[:webhook_secret]

    sig =
      :crypto.mac(:hmac, :sha256, webhook_secret, body)
      |> Base.encode16(case: :lower)

    conn
    |> put_req_header("btcpay-sig", "sha256=#{sig}")
    |> post("/api/webhooks/btcpay", body)
  end

  test "handles InvoiceSettled and creates FilmSubmission", %{conn: conn} do
    json_payload =
      Jason.encode!(%{
        "type" => "InvoiceSettled",
        "invoiceId" => "btc_invoice_abc123"
      })

    conn = signed_post(conn, json_payload)
    assert conn.status == 200

    assert [%FilmSubmission{} = fs] = Timesink.Repo.all(FilmSubmission)
    assert fs.payment_id == "btc_invoice_abc123"
    assert fs.title == "The Luminous Gaze"
  end

  test "handles InvoiceCreated and fetches invoice", %{conn: conn} do
    Timesink.BtcPay
    |> Mox.expect(:fetch_invoice, fn "btc_invoice_new" ->
      {:ok, %{id: "btc_invoice_new", status: "new"}}
    end)

    json_payload =
      Jason.encode!(%{
        "type" => "InvoiceCreated",
        "invoiceId" => "btc_invoice_new"
      })

    conn = signed_post(conn, json_payload)
    assert conn.status == 200
  end

  test "rejects invalid signature", %{conn: conn} do
    bad_sig = put_req_header(conn, "btcpay-sig", "sha256=badsignature")
    conn = post(bad_sig, "/api/webhooks/btcpay", Jason.encode!(%{type: "InvoiceSettled"}))
    assert conn.status == 401
  end
end
