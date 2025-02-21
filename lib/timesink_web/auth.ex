defmodule TimesinkWeb.Auth do
  @moduledoc """
  The Auth module provides functions for managing user authentication.
  """

  import Plug.Conn
  alias Phoenix.Token
  alias Timesink.Accounts.User
  use TimesinkWeb, :verified_routes

  # def plug_check_logged_in(conn, _opts) do
  #   user = get_user_from_session(conn)

  #   if user do
  #     conn
  #     # |> assign(:current_user, user)
  #     |> assign(:is_logged_in, true)
  #   else
  #     conn
  #     |> assign(:is_logged_in, false)
  #   end
  # end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule TimesinkWeb.PageLive do
        use TimesinkWeb, :live_view

        on_mount {TimesinkWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{TimesinkWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.redirect(to: ~p"/sign_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, %{"user_token" => user_token} = _session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      with user_token when not is_nil(user_token) <- user_token,
           user <- get_user_by_session_token(user_token) do
        user
      else
        _ -> nil
      end
    end)
  end

  defp mount_current_user(socket, _session) do
    Phoenix.Component.assign_new(socket, :current_user, fn -> nil end)
  end

  def plug_fetch_current_user(conn, _opts) do
    user = get_user_from_session(conn)
    Plug.Conn.assign(conn, :current_user, user)
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

  # @spec log_in_user(map()) :: Plug.Conn.t
  # def log_in_user(conn, user) do
  #   conn
  #   |> put_session(:current_user_id, user.id)
  # end

  # @spec log_out_user(Plug.Conn.t) :: Plug.Conn.t
  # def log_out_user(conn) do
  #   conn
  #   |> delete_session(:current_user_id)
  # end

  # @spec mount_current_user(Plug.Conn.t) :: Plug.Conn.t
  # def mount_current_user(conn) do
  #   case get_session(conn, :current_user_id) do
  #     nil -> conn
  #     user_id -> conn
  #                 |> assign(:current_user, Timesink.Accounts.User.get_user(user_id))
  #   end
  # end

  # def on_mount(:ensure_authenticated, _params, session, socket) do
  #   case session["current_user"] do
  #     nil ->
  #       socket
  #       |> put_flash(:error, "You must be signed in.")
  #       |> Phoenix.LiveView.redirect(to: "/sign_in")
  #       |> then(fn socket -> {:halt, socket} end)

  #     user ->
  #       {:cont, Phoenix.Component.assign(socket, :current_user, user)}
  #   end
  # end

  defp signed_in_path(_conn), do: ~p"/"
end
