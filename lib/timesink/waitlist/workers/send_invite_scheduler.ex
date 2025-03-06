defmodule TimeSink.InviteScheduler do
  alias TimeSink.Repo
  alias TimeSink.Workers.SendInvite
  alias Oban

  def schedule_invite(applicant_id) do
    # Convert hours to seconds
    delay_seconds = Enum.random(24..72) * 3600
    scheduled_at = DateTime.add(DateTime.utc_now(), delay_seconds, :second)

    with {
           :ok,
           %Oban.Job{
             id: job_id,
             scheduled_at: _scheduled_at
           }
         } <-
           Oban.insert(%Oban.Job{
             queue: :waitlist_invites,
             worker: SendInvite,
             args: %{"applicant_id" => applicant_id},
             scheduled_at: scheduled_at
           }) do
      {:ok, job_id}
    else
      _ ->
        {:error, "Failed to schedule invite"}
    end
  end
end
