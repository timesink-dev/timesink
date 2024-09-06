defmodule Timesink.Repo do
  use Ecto.Repo,
    otp_app: :timesink,
    adapter: Ecto.Adapters.Postgres
end
