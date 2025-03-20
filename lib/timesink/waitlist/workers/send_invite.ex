defmodule Timesink.Workers.SendInvite do
  use Oban.Worker, queue: :waitlist_invites, max_attempts: 3

  alias Timesink.Waitlist.Applicant
  alias Timesink.Token
  alias Timesink.Waitlist.Mail

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"applicant_id" => applicant_id}}) do
    with {:ok, applicant} <- Applicant.get(applicant_id) do
      send_invite(applicant)
    else
      _ -> {:error, "Applicant not found"}
    end
  end

  defp send_invite(%Applicant{email: email, first_name: first_name} = applicant) do
    with {:ok, token} <- generate_and_store_token(applicant),
         {:ok, _} <- Mail.send_invite_code(email, first_name, token.secret) do
      {:ok, token}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp generate_and_store_token(applicant) do
    token = Ecto.UUID.generate()

    # 7 days expiry
    expires_at = DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60, :second)

    token_params = %{
      kind: :invite,
      secret: token,
      waitlist_id: applicant.id,
      expires_at: expires_at
    }

    with {:ok, token} <- Token.create(token_params),
         {:ok, %Applicant{}} <-
           Applicant.update(applicant, %{status: :invited}) do
      {:ok, token}
    else
      {:error, changeset} -> {:error, Ecto.Changeset.traverse_errors(changeset, & &1)}
    end
  end
end
