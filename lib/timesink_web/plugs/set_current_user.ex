defmodule TimesinkWeb.Plugs.SetCurrentUser do
  import Plug.Conn
  alias Phoenix.Token
  alias Timesink.Accounts.User

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)
    assign(conn, :current_user, user)
  end

  defp get_user_from_session(conn) do
    user_token = get_session(conn, :user_token)
    user_token && get_user_by_session_token(user_token)
  end

  defp get_user_by_session_token(user_token) do
    with {:ok, claims} <- Token.verify(TimesinkWeb.Endpoint, "user_auth_salt", user_token),
         user <- Timesink.Repo.get!(User, claims[:user_id]) do
      user |> Timesink.Repo.preload(:profile)
    else
      _ -> nil
    end
  end
end
