defmodule Timesink.Workers.Waitlist.ScheduleInviteJob do
  use Oban.Worker, queue: :waitlist, max_attempts: 3

  import Ecto.Query
  alias Timesink.Repo
  alias Timesink.Waitlist
  alias Timesink.Waitlist.InviteScheduler

  # Number of users invited per batch
  @batch_size 5

  @impl Oban.Worker
  def perform(_job) do
    applicants =
      Repo.all(
        from a in Waitlist.Applicant,
          where: a.status == ^:pending,
          order_by: a.inserted_at,
          limit: @batch_size
      )

    Enum.each(applicants, fn applicant ->
      InviteScheduler.schedule_invite(applicant.id)
    end)

    :ok
  end
end
