defmodule TimesinkWeb.InvitationController do
  use TimesinkWeb, :controller
  alias Timesink.Token
  alias Timesink.Waitlist

  def validate_invite(conn, %{"token" => raw_token}) do
    conn = configure_session(conn, renew: true)

    with {:ok, token} <- Token.validate_invite(raw_token) do
      case Waitlist.get_applicant_by_invite_token(token) do
        {:ok, applicant} ->
          conn
          |> put_session(:invite_token, token)
          |> put_session(:applicant, applicant)
          |> redirect(to: "/onboarding")

        {:not_applicant, :not_found} ->
          conn
          |> put_session(:invite_token, token)
          |> redirect(to: "/onboarding")
      end
    else
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid or expired invite link.")
        |> redirect(to: "/")
    end
  end
end
