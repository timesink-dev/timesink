defmodule TimesinkWeb.Auth do
  @moduledoc """
  The web authentication module for Timesink.

  This module bridges the core authentication logic (from `Timesink.Auth`)
  with web-specific concerns like session management and cookie handling.
  It provides functions to log users in and out, and to fetch the current user
  from the session. Plugs for enforcing authentication have been extracted into
  separate modules under `TimesinkWeb.Plugs`.

    ## Key Functions

    - `log_in_user/3`: Logs the user in by generating a token, renewing the session,
      and storing the token in the session and (optionally) a cookie.
    - `log_out_user/1`: Logs the user out by clearing the session and cookies.
    - `require_authenticated_user/2`: A plug that enforces authentication for protected routes.
    - `authenticate_user/1`: Authenticates a user by checking credentials.
    - `on_mount/4`: Handles mounting and authenticating the current_user in LiveViews.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias Timesink.Auth, as: CoreAuth
  alias Timesink.Accounts.User
  use TimesinkWeb, :verified_routes

  @remember_me_cookie "_timesink_web_user_remember_me"
  @max_age 7 * 60 * 24 * 60
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs in the user.

  Generates a token via core auth logic, renews the session, stores the token
  in the session (and optionally as a remember-me cookie), sets a flash message,
  and redirects the user to their return path or the default signed-in path.
  """
  @spec log_in_user(Plug.Conn.t(), User.t(), map()) :: Plug.Conn.t()
  def log_in_user(conn, user, params \\ %{}) do
    token = CoreAuth.generate_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  @doc """
  Logs out the user by renewing the session, deleting the remember-me cookie,
  and broadcasting a disconnect event to active LiveView sessions.
  """
  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    _user_token = get_session(conn, :user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TimesinkWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates a user based on their credentials.

  Delegates the credential check to the core business logic (e.g. `User.check_credentials/1`).
  Returns `{:ok, user}` on success or `{:error, :invalid_credentials}` on failure.

  ## Examples

      iex> authenticate_user(%{"email" => "foo@example.com", "password" => "correct_password"})
      {:ok, %User{}}

      iex> authenticate_user(%{"email" => "foo@example.com", "password" => "wrong_password"})
      {:error, :invalid_credentials}
  """
  @spec authenticate_user(%{email: binary(), password: binary()}) ::
          {:ok, user :: User.t()} | {:error, :invalid_credentials}
  def authenticate_user(params) do
    with {:ok, user} <- User.check_credentials(params) do
      {:ok, user}
    else
      {:error, :invalid_credentials} -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## on_mount arguments

    * :mount_current_user - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * :ensure_authenticated - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * :redirect_if_user_is_authenticated - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the on_mount lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule TimesinkWeb.PageLive do
        use TimesinkWeb, :live_view

        on_mount {TimesinkWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the live_session of your router to invoke the on_mount callback:

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

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp get_user_by_session_token(user_token) do
    with {:ok, claims} <- CoreAuth.verify_token(user_token),
         user <- Timesink.Repo.get!(User, claims[:user_id]) do
      user
    else
      _ -> nil
    end
  end

  defp signed_in_path(_conn), do: ~p"/now-playing"
end
