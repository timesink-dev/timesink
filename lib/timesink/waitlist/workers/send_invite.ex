defmodule Timesink.Workers.SendInvite do
  use Oban.Worker, queue: :waitlist_invites, max_attempts: 3

  alias Timesink.Waitlist.Applicant
  alias Timesink.Token
  alias Timesink.Waitlist.Mail

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"applicant_id" => applicant_id}}) do
    with {:ok, applicant} = Applicant.get!(applicant_id) do
      send_invite(applicant)
    end
  end

  defp send_invite(%Applicant{id: applicant_id, email: email, first_name: first_name}) do
    with {:ok, token} <- generate_and_store_token(applicant_id),
         {:ok, _} <- Mail.send_invite_code(email, first_name, token.secret) do
      {:ok, token}
    end
  end

  defp generate_and_store_token(applicant_id) do
    token = Ecto.UUID.generate()

    token_params = %{
      kind: :invite,
      secret: token,
      applicant_id: applicant_id
    }

    with {:ok, token} <-
           Token.create(token_params) do
      {:ok, token}
    end
  end
end
