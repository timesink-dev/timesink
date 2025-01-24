defmodule TimesinkWeb.Auth do
  import Plug.Conn
  alias Timesink.Auth

  def plug_bearer_auth(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, _claims} <- Auth.token_auth(token) do
      conn
      |> assign(:current_user, user)
    else
      _ -> conn
    end
  end
end
