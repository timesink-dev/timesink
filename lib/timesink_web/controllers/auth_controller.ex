defmodule TimesinkWeb.AuthController do
  use TimesinkWeb, :controller

  alias TimesinkWeb.Auth

  @spec sign_in(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sign_in(
        conn,
        %{"user" => %{"email" => email, "password" => password} = user_params} = _params
      ) do
    with {:ok, user} <-
           Auth.authenticate_user(%{email: email, password: password}) do
      conn
      |> maybe_put_return_to(user_params)
      |> Auth.log_in_user(user)
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/sign-in")
    end
  end

  defp maybe_put_return_to(conn, %{"return_to" => return_to})
       when is_binary(return_to) and return_to != "" do
    import Plug.Conn, only: [put_session: 3]
    put_session(conn, :user_return_to, return_to)
  end

  defp maybe_put_return_to(conn, _), do: conn

  def sign_out(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:success, "You have logged out succesfully.")
  end

  @spec complete_onboarding(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def complete_onboarding(conn, %{"token" => token}) do
    conn
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> redirect(to: "/now-playing?welcome=1")
  end

  @doc """
  Handles email verification from the link sent to the user's new email address.
  Verifies the token and updates the user's email if valid.
  """
  @spec verify_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_email(conn, %{"token" => token}) do
    case Timesink.Account.verify_email_change_token(token) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:success, "Email address verified successfully!")
        |> redirect(to: ~p"/me/profile")

      {:error, :invalid_or_expired} ->
        conn
        |> put_flash(
          :error,
          "This verification link is invalid or has expired. Please try again."
        )
        |> redirect(to: ~p"/me/profile")

      {:error, __reason} ->
        conn
        |> put_flash(:error, "Failed to verify email address. Please try again.")
        |> redirect(to: ~p"/me/profile")
    end
  end
end
