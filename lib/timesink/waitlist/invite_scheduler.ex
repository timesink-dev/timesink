defmodule Timesink.Waitlist.InviteScheduler do
  alias Timesink.Workers.SendInvite
  alias Oban

  def schedule_invite(applicant_id) do
    # Convert hours to seconds
    delay_seconds = Enum.random(24..72) * 3600
    scheduled_at = DateTime.add(DateTime.utc_now(), delay_seconds, :second)

    # Use the worker's new/2 function
    job = SendInvite.new(%{"applicant_id" => applicant_id}, scheduled_at: scheduled_at)

    case Oban.insert(job) do
      {:ok, job} -> {:ok, job.id}
      {:error, _} -> {:error, "Failed to schedule invite"}
    end
  end
end
