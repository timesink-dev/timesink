defmodule TimesinkWeb.Plugs.RequireAuthenticatedUser do
  import Plug.Conn
  alias Phoenix.Token
  alias Timesink.Accounts.User
  import Phoenix.Controller
  use TimesinkWeb, :verified_routes

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)

    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/sign_in")
      |> halt()
    end
  end

  defp get_user_from_session(conn) do
    user_token = get_session(conn, :user_token)
    user_token && get_user_by_session_token(user_token)
  end

  defp get_user_by_session_token(user_token) do
    with {:ok, claims} <- Token.verify(TimesinkWeb.Endpoint, "user_auth_salt", user_token),
         user <- Timesink.Repo.get!(User, claims[:user_id]) do
      user
    else
      _ -> nil
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    IO.inspect(current_path(conn), label: "maybe_store_return_to")
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn) do
    IO.inspect(conn, label: "maybe_store_return_to just conn")
    put_session(conn, :user_return_to, current_path(conn))
  end
end
