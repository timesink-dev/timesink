defmodule Timesink.Workers.Waitlist.CleanExpiredInvitesJob do
  use Oban.Worker, queue: :waitlist, max_attempts: 3
  import Ecto.Query
  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant
  alias Timesink.Token

  @impl Oban.Worker
  def perform(_job) do
    now = DateTime.utc_now()

    expired_applicants =
      Repo.all(
        from a in Applicant,
          join: t in Token,
          on: t.waitlist_id == a.id,
          where: t.expires_at < ^now and t.kind == :invite and a.status != :completed,
          select: a
      )

    Enum.each(expired_applicants, &Repo.delete!/1)
  end
end
