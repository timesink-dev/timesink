defmodule Timesink.Workers.CleanExpiredWaitlistInvites do
  use Oban.Worker, queue: :waitlist_cleanup, max_attempts: 3
  import Ecto.Query
  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant
  alias Timesink.Token

  @impl Oban.Worker
  def perform(_job) do
    now = DateTime.utc_now()

    expired_tokens =
      Repo.all(
        from t in Token,
          where: t.expires_at < ^now and t.kind == :invite,
          join: a in Applicant,
          on: a.id == t.waitlist_id,
          where: a.status != :completed,
          select: {t, a}
      )

    Enum.each(expired_tokens, fn {token, applicant} ->
      Repo.delete!(token)
      Repo.delete!(applicant)
    end)
  end
end
