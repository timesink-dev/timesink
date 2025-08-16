defmodule TimesinkWeb.GhostPublishingController do
  use TimesinkWeb, :controller
  require Logger

  alias TimesinkWeb.GhostPublishingWebhookHandler

  plug :verify_ghost_signature

  def webhook(%Plug.Conn{assigns: %{raw_body: raw}} = conn, %{"event_type" => type}) do
    with {:ok, data} <- Jason.decode(raw) do
      Logger.info("Received Ghost webhook data: #{inspect(data)}")

      GhostPublishingWebhookHandler.handle_event(%{
        "type" => type,
        "data" => data
      })

      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.error("Failed to parse Ghost webhook: #{inspect(reason)}")
        send_resp(conn, 400, "bad request")
    end
  end

  defp verify_ghost_signature(conn, _opts) do
    raw_body = conn.assigns[:raw_body] || conn.params["raw_body"]

    ghost_secret =
      Application.fetch_env!(:timesink, :ghost_publishing)
      |> Keyword.fetch!(:webhook_key)

    case Plug.Conn.get_req_header(conn, "x-ghost-signature") do
      [header] ->
        ["sha256=" <> received_sig, timestamp] = String.split(header, ", t=")

        expected_sig =
          :crypto.mac(:hmac, :sha256, ghost_secret, raw_body <> timestamp)
          |> Base.encode16(case: :lower)

        Logger.debug("Raw body: #{raw_body}")
        Logger.debug("Expected: #{expected_sig}")
        Logger.debug("Received: #{received_sig}")

        if Plug.Crypto.secure_compare(expected_sig, String.downcase(received_sig)) do
          assign(conn, :raw_body, raw_body)
        else
          Logger.warning(%{
            service: :ghost,
            expected: expected_sig,
            received: received_sig
          })

          conn |> send_resp(401, "Unauthorized") |> halt()
        end

      _ ->
        Logger.warning("Missing or malformed Ghost webhook signature")
        conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end
end
