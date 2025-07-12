# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :timesink,
  ecto_repos: [Timesink.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :timesink, TimesinkWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TimesinkWeb.ErrorHTML, json: TimesinkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Timesink.PubSub,
  live_view: [signing_salt: "/iQY4AR5"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :timesink, Timesink.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  timesink: [
    args:
      ~w(js/app.js --bundle --target=es2020 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  timesink: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws,
  json_codec: Jason,
  access_key_id: [{:system, "TIMESINK_S3_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "TIMESINK_S3_ACCESS_KEY_SECRET"}, :instance_role]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :timesink, Oban,
  engine: Oban.Engines.Basic,
  repo: Timesink.Repo,
  plugins: [
    Oban.Plugins.Lifeline,
    {Oban.Plugins.Pruner, max_age: 3600},

    # Oban.Plugins.Reindexer requires the `CONCURRENT` option, which is only
    # available in Postgres 12 and above.
    {Oban.Plugins.Reindexer, schedule: "@weekly"},
    {Oban.Plugins.Cron,
     crontab: [
       {"@daily", Timesink.Workers.Waitlist.ScheduleInviteJob}

       # Runs every 1 minute for dev env
       #  {"*/1 * * * *", Timesink.Workers.Waitlist.ScheduleInviteJob}
     ]}
  ],
  queues: [mailer: 10, waitlist: 10]

config :timesink, :finch, Timesink.Finch

config :timesink, :http_client, Timesink.HTTP.FinchClient

config :timesink, :here_maps_api_key, System.get_env("TIMESINK_HERE_MAPS_API_KEY")

config :tesla, adapter: {Tesla.Adapter.Finch, name: Timesink.Finch}

config :timesink, Timesink.Storage.Mux, webhook_key: "mux-test"

config :timesink, :ghost_content,
  host: "https://timesink.ghost.io/",
  api_key: System.get_env("TIMESINK_GHOST_CONTENT_API_KEY")
