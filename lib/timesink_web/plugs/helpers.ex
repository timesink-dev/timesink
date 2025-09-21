defmodule TimesinkWeb.Plugs.Helpers do
  @moduledoc """
  Provides helper functions for authentication-related plugs.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias Timesink.Auth, as: CoreAuth

  def get_user_from_session(conn) do
    user_token = Plug.Conn.get_session(conn, :user_token)
    if user_token, do: get_user_by_session_token(user_token), else: nil
  end

  defp get_user_by_session_token(user_token) do
    with {:ok, claims} <-
           CoreAuth.verify_token(user_token),
         user when not is_nil(user) <-
           Timesink.Repo.get!(Timesink.Account.User, claims[:user_id]) do
      user
    else
      _ -> nil
    end
  end

  def maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  def maybe_store_return_to(conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end
end
