defmodule TimesinkWeb.Plugs.CanonicalHost do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    canonical_host = System.get_env("PHX_HOST")

    cond do
      # No PHX_HOST → dev / test / local → do nothing
      is_nil(canonical_host) ->
        conn

      # Already on canonical host → do nothing
      conn.host == canonical_host ->
        conn

      # Redirect everything else → canonical
      true ->
        location =
          "https://#{canonical_host}#{conn.request_path}" <>
            if(conn.query_string != "", do: "?" <> conn.query_string, else: "")

        conn
        |> put_resp_header("location", location)
        |> send_resp(301, "")
        |> halt()
    end
  end
end
