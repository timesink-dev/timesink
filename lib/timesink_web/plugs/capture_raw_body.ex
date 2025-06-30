defmodule TimesinkWeb.Plugs.CaptureRawBody do
  @moduledoc """
  A plug to capture the raw body of requests to the BTC Pay webhook endpoint.
  This is necessary for signature verification, as the raw body must be used
  to compute the HMAC signature.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/api/webhooks/btc-pay.server"} = conn, _opts) do
    case read_body(conn) do
      {:ok, body, conn} ->
        # Save raw body for signature verification
        assign(conn, :raw_body, body)

      {:more, _partial, conn} ->
        assign(conn, :raw_body, nil)
    end
  end

  def call(conn, _opts), do: conn
end
