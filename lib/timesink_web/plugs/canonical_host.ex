defmodule TimesinkWeb.Plugs.CanonicalHost do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if Application.get_env(:timesink, :canonical_host_redirect, true) do
      canonical_host = System.get_env("PHX_HOST")

      cond do
        is_nil(canonical_host) ->
          conn

        conn.host == canonical_host ->
          conn

        true ->
          location =
            "https://#{canonical_host}#{conn.request_path}" <>
              if(conn.query_string != "", do: "?" <> conn.query_string, else: "")

          conn
          |> put_resp_header("location", location)
          |> send_resp(301, "")
          |> halt()
      end
    else
      conn
    end
  end
end
