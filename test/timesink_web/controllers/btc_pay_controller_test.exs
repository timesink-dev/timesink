defmodule TimesinkWeb.BtcPayControllerTest do
  use TimesinkWeb.ConnCase
  import Timesink.Factory
  alias Timesink.Cinema.FilmSubmission

  @webhook_secret System.get_env("TIMESINK_TEST_BTC_PAY_WEBHOOK_SECRET")

  # Replace with actual HMAC if needed
  @valid_sig "validsig123"

  test "handles InvoiceSettled and creates FilmSubmission", %{conn: conn} do
    user = insert(:user)

    json_payload =
      Jason.encode!(%{
        "type" => "InvoiceSettled",
        "invoiceId" => "btc_invoice_abc123",
        "metadata" => %{
          "title" => "The Luminous Gaze",
          "year" => "2024",
          "duration_min" => "15",
          "synopsis" => "A test synopsis",
          "video_url" => "https://vimeo.com/123",
          "video_pw" => "pw123",
          "contact_name" => "Test User",
          "contact_email" => "test@example.com",
          "payment_id" => "btc_invoice_abc123",
          "submitted_by_id" => user.id
        }
      })

    conn = signed_post(conn, json_payload)
    assert conn.status == 200

    assert [%FilmSubmission{} = fs] = Timesink.Repo.all(FilmSubmission)
    assert fs.payment_id == "btc_invoice_abc123"
    assert fs.title == "The Luminous Gaze"
  end

  test "handles InvoiceCreated", %{conn: conn} do
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
    conn = post(bad_sig, "/api/webhooks/btc-pay.server", Jason.encode!(%{type: "InvoiceSettled"}))
    assert conn.status == 401
  end

  defp signed_post(conn, body) do
    sig =
      :crypto.mac(:hmac, :sha256, @webhook_secret, body)
      |> Base.encode16(case: :lower)

    conn
    |> put_req_header("btcpay-sig", "sha256=#{sig}")
    |> put_req_header("content-type", "application/json")
    |> post("/api/webhooks/btc-pay.server", body)
  end
end
