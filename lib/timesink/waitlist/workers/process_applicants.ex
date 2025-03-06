defmodule Timesink.Workers.ProcessWaitlist do
  use Oban.Worker, queue: :waitlist_processing, max_attempts: 3

  import Ecto.Query
  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant
  alias Timesink.Waitlist.InviteScheduler

  # Number of users invited per batch
  @batch_size 10

  @impl Oban.Worker
  def perform(_job) do
    applicants =
      Repo.all(
        from a in Applicant,
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
