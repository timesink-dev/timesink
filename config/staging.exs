import Config

config :timesink, TimesinkWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :timesink, :session_cookie_key, "_timesink_staging_key"

config :timesink, Timesink.Mailer, adapter: Resend.Swoosh.Adapter

config :swoosh,
  api_client: Swoosh.ApiClient.Finch,
  finch_name: Timesink.Finch,
  local: false

config :logger, level: :info

# Runtime config is still handled by runtime.exs
