defmodule TimesinkWeb.InvitationController do
  use TimesinkWeb, :controller
  alias Timesink.Token
  alias Timesink.Waitlist

  def validate_invite(conn, %{"token" => token}) do
    # clear any open session (reset) before continuing
    conn = configure_session(conn, renew: true)

    with {:ok, token} <- Token.validate_invite(token),
         {:ok, applicant} <- Waitlist.get_applicant_by_invite_token(token) do
      conn
      |> put_session(:invite_token, token)
      |> put_session(:applicant, applicant)
      |> redirect(to: "/onboarding")
    else
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid or expired invite link.")
        |> redirect(to: "/")
    end
  end
end
