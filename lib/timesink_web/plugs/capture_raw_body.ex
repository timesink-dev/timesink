defmodule TimesinkWeb.Plugs.CaptureRawBody do
  @moduledoc """
  A plug to capture the raw body of requests to the BTC Pay webhook endpoint.
  This is necessary for signature verification, as the raw body must be used
  to compute the HMAC signature.
  """

  import Plug.Conn

  @webhook_paths [
    "/api/webhooks/btc-pay.server",
    ~r|^/api/webhooks/ghost\.io/.*|
  ]

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: path} = conn, _opts) do
    if Enum.any?(@webhook_paths, fn
         p when is_binary(p) -> path == p
         %Regex{} = r -> Regex.match?(r, path)
       end) do
      case read_body(conn) do
        {:ok, body, conn} ->
          assign(conn, :raw_body, body)

        {:more, _partial, conn} ->
          assign(conn, :raw_body, nil)
      end
    else
      conn
    end
  end

  def call(conn, _opts), do: conn
end
