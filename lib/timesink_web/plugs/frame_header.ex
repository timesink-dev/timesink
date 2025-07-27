defmodule TimesinkWeb.Plugs.FrameHeader do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(get_resp_header(conn, "x-frame-options"), label: "Before removing XFO")

    conn
    |> put_resp_header("content-security-policy", "frame-ancestors *")
    |> delete_resp_header("x-frame-options")

    # or explicitly allow embedding from ngrok:
    # |> put_resp_header("x-frame-options", "ALLOW-FROM https://*.ngrok-free.app")
  end
end
