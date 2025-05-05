defmodule Timesink.Waitlist.InviteScheduler do
  alias Timesink.Workers.Waitlist.SendInviteJob
  alias Oban

  # a random delay between 24 and 72 hours
  @delay_range 24..72

  # 1 hour in seconds
  @delay_seconds 3600

  def schedule_invite(applicant_id) do
    delay_seconds = Enum.random(@delay_range) * @delay_seconds
    scheduled_at = DateTime.add(DateTime.utc_now(), delay_seconds, :second)

    job = SendInviteJob.new(%{"applicant_id" => applicant_id}, scheduled_at: scheduled_at)

    case Oban.insert(job) do
      {:ok, job} -> {:ok, job.id}
      {:error, _} -> {:error, "Failed to schedule invite"}
    end
  end
end
