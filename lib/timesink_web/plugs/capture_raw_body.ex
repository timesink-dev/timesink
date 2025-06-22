defmodule TimesinkWeb.Plugs.CaptureRawBody do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(read_body(conn), label: "Raw Body Capture")

    case read_body(conn) do
      {:ok, body, conn} ->
      conn |> assign(:raw_body, body)

      {:more, _partial_body, conn} ->
        # If the body is too large to read in one go
        conn |> assign(:raw_body, nil)
    end
  end
end
