defmodule Timesink.Accounts.Auth do
  @moduledoc """
  The Auth context.
  """

  alias Phoenix.Token
  use TimesinkWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  alias Timesink.Accounts.User

  # Change this to your own secret
  @token_salt "user_auth_salt"

  # Make the remember me cookie valid for 7 days.
  @max_age 7 * 60 * 24 * 60
  @remember_me_cookie "_timesink_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def generate_token(user) do
    Token.sign(TimesinkWeb.Endpoint, @token_salt, %{user_id: user.id, role: user.roles})
  end

  def verify_token(token) do
    Token.verify(TimesinkWeb.Endpoint, @token_salt, token, max_age: @max_age)
  end

  @spec log_in_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = generate_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> put_current_user_in_assigns(user)
    |> maybe_write_remember_me_cookie(token, params)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    _user_token = get_session(conn, :user_token)

    # TODO remove add user_token to BadToken's list of revoked tokens ?
    # Anything else to do here?

    if live_socket_id = get_session(conn, :live_socket_id) do
      TimesinkWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && token_auth(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

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

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        case Token.verify(TimesinkWeb.Endpoint, "user_auth_salt", user_token) do
          {:ok, claims} ->
            user = Timesink.Repo.get!(User, claims[:user_id]) |> Timesink.Repo.preload(:profile)
            user

          {:error, _} ->
            nil
        end
      else
        nil
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    IO.inspect(conn.assigns[:current_user],
      label: "current_user in plug redirect_if_user_is_authenticated"
    )

    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    IO.inspect(conn, label: "current_user in plug")

    if conn.assigns[:current_user] do
      IO.inspect(conn.assigns[:current_user], label: "current_user in plug past")
      conn
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/sign_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"

  # @spec token_auth(token_or_claims :: String.t() | %{}) ::
  #         {:ok, User.t(), Guardian.Token.claims()} | {:error, :bad_credentials}
  def token_auth(token) when is_binary(token) do
    with {:ok, _claims} <- verify_token(token) do
      # token_auth(claims)
    else
      _error ->
        # TODO: log error
        {:error, :bad_credentials}
    end
  end

  # TODO: Validate against BadToken's list of revoked tokens
  # def token_auth(claims) when is_map(claims) do
  #   with {:ok, :not_bad} <- BadToken.verify(claims),
  #        {:ok, user} <- User.get(claims["sub"]) do
  #     {:ok, user, claims}
  #   else
  #     _error ->
  #       # TODO: log error
  #       {:error, :bad_credentials}
  #   end
  # end

  defp put_current_user_in_assigns(conn, user) do
    user = user |> Timesink.Repo.preload(:profile)

    conn
    |> assign(:current_user, user)
  end
end
