defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias TimesinkWeb.Auth

  @spec sign_in(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}} = _params) do
    with {:ok, user} <-
           Auth.authenticate_user(%{email: email, password: password}) do
      conn
      |> Auth.log_in_user(user)
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/sign_in")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:info, "You have logged out succesfully.")
  end

  @spec complete_onboarding(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def complete_onboarding(conn, %{"token" => token}) do
    conn
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> put_flash(:info, "Welcome to Timesink!")
    |> redirect(to: "/now-playing")
  end

  def iframe_start(conn, _params) do
    IO.inspect("HERE")

    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/auth/iframe_complete")
    else
      redirect(conn, to: ~p"/sign_in?return_to=/auth/iframe_complete")
    end
  end

  def iframe_complete(conn, _params) do
    user = conn.assigns[:current_user] || raise "not signed in"
    # Put exactly what you want the iframe to know:
    claims = %{uid: user.id, name: user.first_name, avatar: ""}
    token = Phoenix.Token.sign(TimesinkWeb.Endpoint, "iframe:auth", claims)

    IO.inspect("YO!")

    html = """
    <script>
      try {
        (window.opener || window.parent).postMessage({ ts_auth_token: #{Jason.encode!(token)} }, "*");
      } catch(_) {}
      window.close();
    </script>
    """

    Plug.Conn.resp(conn, 200, html)
  end
end
