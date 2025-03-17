defmodule TimesinkWeb.InvitationController do
  use TimesinkWeb, :controller
  alias Timesink.Token

  def validate_invite(conn, %{"token" => token}) do
    with {:ok, token} <- Token.validate_invite(token) do
      conn
      |> put_session(:invite_token, token)
      |> redirect(to: "/onboarding")
    else
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid or expired invite link.")
        |> redirect(to: "/")
    end
  end
end
