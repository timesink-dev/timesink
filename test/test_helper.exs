{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Timesink.Repo, :manual)

Mox.defmock(Timesink.MockHTTPClient, for: Timesink.HTTP)
Application.put_env(:timesink, :http_client, Timesink.MockHTTPClient)

Mox.set_mox_global()
