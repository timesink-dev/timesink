defmodule TimesinkWeb.StripeControllerTest do
  use TimesinkWeb.ConnCase
  import Timesink.Factory

  alias Timesink.Cinema.FilmSubmission

  describe "POST /api/webhooks/stripe.com" do
    test "handles payment_intent.succeeded and creates a FilmSubmission", %{conn: conn} do
      user = insert(:user)

      params = %{
        "type" => "payment_intent.succeeded",
        "data" => %{
          "object" => %{
            "id" => "pi_test_123",
            "metadata" => %{
              "title" => "Test Film",
              "year" => "2024",
              "duration_min" => "15",
              "synopsis" => "A test synopsis",
              "video_url" => "https://vimeo.com/123",
              "video_pw" => "pw123",
              "contact_name" => "Test User",
              "contact_email" => "test@example.com",
              "submitted_by_id" => user.id
            }
          }
        }
      }

      conn = post(conn, ~p"/api/webhooks/stripe.com", params)
      assert conn.status == 204

      assert fs = Timesink.Repo.all(FilmSubmission)
      assert hd(fs).title == "Test Film"
      assert hd(fs).payment_id == "pi_test_123"
      assert hd(fs).submitted_by_id == user.id
    end

    test "ignores unhandled event types", %{conn: conn} do
      conn =
        post(conn, ~p"/api/webhooks/stripe.com", %{"type" => "invoice.paid", "data" => %{}})

      assert conn.status == 204
    end
  end
end
