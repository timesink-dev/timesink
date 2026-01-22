defmodule TimesinkWeb.Plugs.EnsureCanonicalUrl do
  @moduledoc """
  Ensures all requests use the canonical URL format:
  - HTTPS protocol
  - Non-www domain (timesinkpresents.com)
  - No trailing slashes (except root path "/")

  Redirects with 301 (permanent) to the canonical URL if needed.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    canonical_host = "timesinkpresents.com"

    # Skip redirects for local development and staging
    if conn.host in ["localhost", "127.0.0.1", "staging.timesinkpresents.com"] do
      conn
    else
      needs_redirect? =
        conn.scheme != :https or
          conn.host != canonical_host or
          has_trailing_slash?(conn)

      if needs_redirect? do
        redirect_to_canonical(conn, canonical_host)
      else
        conn
      end
    end
  end

  defp has_trailing_slash?(conn) do
    # Allow trailing slash only for root path
    conn.request_path != "/" and String.ends_with?(conn.request_path, "/")
  end

  defp redirect_to_canonical(conn, canonical_host) do
    # Remove trailing slash unless it's the root path
    path =
      if has_trailing_slash?(conn) do
        String.trim_trailing(conn.request_path, "/")
      else
        conn.request_path
      end

    # Preserve query string if present
    query_string = if conn.query_string != "", do: "?#{conn.query_string}", else: ""

    canonical_url = "https://#{canonical_host}#{path}#{query_string}"

    conn
    |> put_status(:moved_permanently)
    |> redirect(external: canonical_url)
    |> halt()
  end
end
