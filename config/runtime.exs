import Config

env = config_env()

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
fetch_env! = fn key ->
  System.get_env(key) ||
    raise """
    environment variable #{key} is missing.
    """
end

get_port = fn ->
  String.to_integer(System.get_env("PORT") || "4000")
end

# -----------------------------------------------------------------------------
# Common (all environments)
# -----------------------------------------------------------------------------

if System.get_env("PHX_SERVER") do
  config :timesink, TimesinkWeb.Endpoint, server: true
end

# Session cookie key (set per Fly app via secrets)
config :timesink, :session_cookie_key, System.get_env("SESSION_COOKIE_KEY") || "_timesink_key"

# Repo
database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

config :timesink, Timesink.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: maybe_ipv6

# Default HTTP client adapter
config :timesink, :http_client, Timesink.HTTP.FinchClient

# Base URL per env (used by your app logic)
base_url =
  case env do
    :dev ->
      System.get_env("TIMESINK_DEV_URL") || "http://localhost:4000"

    :test ->
      "http://localhost:4001"

    :staging ->
      System.get_env("TIMESINK_STAGING_URL") || "https://staging.timesinkpresents.com"

    :prod ->
      System.get_env("TIMESINK_PROD_URL") || "https://timesinkpresents.com"
  end

config :timesink, base_url: base_url

# HERE Maps
config :timesink, :here_maps_api_key, System.get_env("TIMESINK_HERE_MAPS_API_KEY")

# DNS cluster query only relevant on Fly, safe to set for all envs
config :timesink, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

# -----------------------------------------------------------------------------
# Endpoint
# -----------------------------------------------------------------------------
case env do
  :dev ->
    # Dev endpoint stays in config/dev.exs usually.
    # Nothing required here unless you want runtime overrides.
    :ok

  :test ->
    # Test endpoint also generally in config/test.exs.
    :ok

  :staging ->
    secret_key_base = fetch_env!.("SECRET_KEY_BASE")
    port = get_port.()

    # IMPORTANT: staging host is explicit; does not depend on prod secrets.
    host = System.get_env("PHX_HOST") || "staging.timesinkpresents.com"

    config :timesink, TimesinkWeb.Endpoint,
      url: [host: host, port: 443, scheme: "https"],
      check_origin: [
        "https://staging.timesinkpresents.com",
        "https://timesink-staging.fly.dev"
      ],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base

    # ExAws region (real AWS in staging)
    config :ex_aws, region: fetch_env!.("TIMESINK_AWS_REGION")

  :prod ->
    secret_key_base = fetch_env!.("SECRET_KEY_BASE")
    port = get_port.()

    host = System.get_env("PHX_HOST") || "timesinkpresents.com"

    config :timesink, TimesinkWeb.Endpoint,
      url: [host: host, port: 443, scheme: "https"],
      check_origin: [
        "https://timesinkpresents.com",
        "https://www.timesinkpresents.com"
      ],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base

    # ExAws region (real AWS in prod)
    config :ex_aws, region: fetch_env!.("TIMESINK_AWS_REGION")
end

# -----------------------------------------------------------------------------
# :dev
# -----------------------------------------------------------------------------
if env == :dev do
  # ExAws creds + region (MinIO ignores region, ExAws needs a value)
  config :ex_aws,
    access_key_id: System.get_env("TIMESINK_DEV_S3_ACCESS_KEY_ID", "minioadmin"),
    secret_access_key: System.get_env("TIMESINK_DEV_S3_ACCESS_KEY_SECRET", "minioadmin"),
    region: System.get_env("AWS_REGION", "eu-west-3")

  # Point S3 client at MinIO and force path-style URLs
  minio = URI.parse(System.get_env("TIMESINK_DEV_S3_HOST", "http://localhost:9000"))

  config :ex_aws, :s3,
    scheme: "#{minio.scheme}://",
    host: minio.host,
    port: minio.port || 9000,
    region: System.get_env("AWS_REGION", "eu-west-3"),
    virtual_host: false,
    http_opts: (minio.scheme == "https" && [ssl_options: [verify: :verify_none]]) || []

  # Your app’s S3 settings (used for public_url/building URIs)
  config :timesink, Timesink.Storage.S3,
    provider: :minio,
    host: System.get_env("TIMESINK_DEV_S3_HOST", "http://localhost:9000"),
    access_key_id: System.get_env("TIMESINK_DEV_S3_ACCESS_KEY_ID", "minioadmin"),
    access_key_secret: System.get_env("TIMESINK_DEV_S3_ACCESS_KEY_SECRET", "minioadmin"),
    bucket: System.get_env("TIMESINK_DEV_S3_BUCKET", "timesink-dev"),
    prefix: System.get_env("TIMESINK_DEV_S3_PREFIX", "blobs")

  # Mux (dev defaults)
  config :timesink, Timesink.Storage.Mux,
    webhook_key: System.get_env("TIMESINK_MUX_WEBHOOK_KEY", "MUX_WEBHOOK_KEY/DEV"),
    access_key_id: System.get_env("TIMESINK_MUX_ACCESS_KEY_ID"),
    access_key_secret: System.get_env("TIMESINK_MUX_ACCESS_KEY_SECRET")

  # BTC Pay (dev)
  config :timesink, :btc_pay,
    api_key: System.get_env("TIMESINK_TEST_BTC_PAY_API_KEY", "test-api-key"),
    url: System.get_env("TIMESINK_TEST_BTC_PAY_API_URL", "http://localhost:23000"),
    store_id: System.get_env("TIMESINK_TEST_BTC_PAY_STORE_ID", "test-store-id"),
    webhook_secret: System.get_env("TIMESINK_TEST_BTC_PAY_WEBHOOK_SECRET", "test-secret"),
    webhook_url:
      System.get_env("TIMESINK_TEST_BTC_PAY_WEBHOOK_URL") ||
        "http://localhost:4000/api/btc_pay/webhook"

  # Stripe (dev)
  config :timesink, :stripe,
    secret_key: System.get_env("TIMESINK_TEST_STRIPE_SECRET_KEY", "test-api-key"),
    publishable_key: System.get_env("TIMESINK_TEST_STRIPE_PUBLISHABLE_KEY", "test-publishable")

  config :stripity_stripe,
    api_key: System.get_env("TIMESINK_TEST_STRIPE_SECRET_KEY")

  # Resend (dev)
  config :timesink, :resend,
    api_key: System.get_env("TIMESINK_RESEND_API_KEY", "dev-api-key"),
    audience_id: System.get_env("TIMESINK_RESEND_AUDIENCE_ID", "dev-audience-id")
end

# -----------------------------------------------------------------------------
# :test
# -----------------------------------------------------------------------------
if env == :test do
  # Point ExAws S3 at test MinIO instance
  System.get_env("TIMESINK_TEST_S3_HOST", "http://localhost:9000")
  |> URI.parse()
  |> then(fn %{scheme: scheme, host: host, port: port} ->
    config :ex_aws, :s3, scheme: "#{scheme}://", host: host, port: port
  end)

  config :timesink, Timesink.Storage.S3,
    host: System.get_env("TIMESINK_TEST_S3_HOST", "http://localhost:9000"),
    access_key_id: System.get_env("TIMESINK_TEST_S3_ACCESS_KEY_ID", "minioadmin"),
    access_key_secret: System.get_env("TIMESINK_TEST_S3_ACCESS_KEY_SECRET", "minioadmin"),
    bucket: System.get_env("TIMESINK_TEST_S3_BUCKET", "timesink-test"),
    prefix: System.get_env("TIMESINK_TEST_S3_PREFIX", "blobs")

  # Mux (test)
  config :timesink, Timesink.Storage.Mux,
    webhook_key: System.get_env("TIMESINK_TEST_MUX_WEBHOOK_KEY", "MUX_WEBHOOK_KEY_TEST"),
    access_key_id: System.get_env("TIMESINK_TEST_MUX_ACCESS_KEY_ID", "MUX_ACCESS_KEY_ID_TEST"),
    access_key_secret:
      System.get_env("TIMESINK_TEST_MUX_ACCESS_KEY_SECRET", "MUX_ACCESS_KEY_SECRET")

  # BTC Pay (test)
  config :timesink, :btc_pay,
    api_key: System.get_env("TIMESINK_TEST_BTC_PAY_API_KEY", "test-api-key"),
    url: System.get_env("TIMESINK_TEST_BTC_PAY_API_URL", "http://localhost:23000"),
    store_id: System.get_env("TIMESINK_TEST_BTC_PAY_STORE_ID", "test-store-id"),
    webhook_secret:
      System.get_env("TIMESINK_TEST_BTC_PAY_WEBHOOK_SECRET", "BTC_PAY_WEBHOOK_SECRET_TEST"),
    webhook_url:
      System.get_env("TIMESINK_TEST_BTC_PAY_WEBHOOK_URL") ||
        "http://localhost:4000/api/btc_pay/webhook"
end

# -----------------------------------------------------------------------------
# :staging
# -----------------------------------------------------------------------------
if env == :staging do
  # Mailer
  config :timesink, Timesink.Mailer, api_key: fetch_env!.("TIMESINK_STAGING_RESEND_API_KEY")

  config :timesink, :resend,
    api_key: fetch_env!.("TIMESINK_STAGING_RESEND_API_KEY"),
    audience_id: fetch_env!.("TIMESINK_STAGING_RESEND_AUDIENCE_ID")

  # Stripe (staging)
  config :timesink, :stripe,
    secret_key: System.get_env("TIMESINK_STAGING_STRIPE_SECRET_KEY", "staging-api-key"),
    publishable_key:
      System.get_env("TIMESINK_STAGING_STRIPE_PUBLISHABLE_KEY", "staging-publishable")

  config :stripity_stripe,
    api_key: System.get_env("TIMESINK_STAGING_STRIPE_SECRET_KEY")

  # S3 (staging)
  config :timesink, Timesink.Storage.S3,
    host: fetch_env!.("TIMESINK_STAGING_S3_HOST"),
    access_key_id: fetch_env!.("TIMESINK_STAGING_S3_ACCESS_KEY_ID"),
    access_key_secret: fetch_env!.("TIMESINK_STAGING_S3_ACCESS_KEY_SECRET"),
    bucket: fetch_env!.("TIMESINK_STAGING_S3_BUCKET"),
    prefix: fetch_env!.("TIMESINK_STAGING_S3_PREFIX")

  # Mux (staging)
  config :timesink, Timesink.Storage.Mux,
    webhook_key: fetch_env!.("TIMESINK_STAGING_MUX_WEBHOOK_KEY"),
    access_key_id: fetch_env!.("TIMESINK_STAGING_MUX_ACCESS_KEY_ID"),
    access_key_secret: fetch_env!.("TIMESINK_STAGING_MUX_ACCESS_KEY_SECRET")

  # BTC Pay (staging)
  config :timesink, :btc_pay,
    api_key: System.get_env("TIMESINK_STAGING_BTC_PAY_API_KEY", "staging-api-key"),
    url:
      System.get_env("TIMESINK_STAGING_BTC_PAY_API_URL", "https://mainnet.demo.btcpayserver.org"),
    store_id:
      System.get_env(
        "TIMESINK_STAGING_BTC_PAY_STORE_ID",
        "FHJN57hrurbPVV5ntabDALMna9bvM7NmDAYV3wnagJXP"
      ),
    webhook_secret:
      System.get_env("TIMESINK_STAGING_BTC_PAY_WEBHOOK_SECRET", "staging-webhook-secret"),
    webhook_url:
      System.get_env("TIMESINK_STAGING_BTC_PAY_WEBHOOK_URL") ||
        "https://staging.timesinkpresents.com/api/webhooks/btc-pay.server"
end

# -----------------------------------------------------------------------------
# :prod
# -----------------------------------------------------------------------------
if env == :prod do
  # Mailer
  config :timesink, Timesink.Mailer, api_key: fetch_env!.("TIMESINK_RESEND_API_KEY")

  config :timesink, :resend,
    api_key: fetch_env!.("TIMESINK_RESEND_API_KEY"),
    audience_id: fetch_env!.("TIMESINK_RESEND_AUDIENCE_ID")

  # S3 (prod)
  config :timesink, Timesink.Storage.S3,
    host: fetch_env!.("TIMESINK_S3_HOST"),
    access_key_id: fetch_env!.("TIMESINK_S3_ACCESS_KEY_ID"),
    access_key_secret: fetch_env!.("TIMESINK_S3_ACCESS_KEY_SECRET"),
    bucket: fetch_env!.("TIMESINK_S3_BUCKET"),
    prefix: fetch_env!.("TIMESINK_S3_PREFIX")

  # Mux (prod)
  config :timesink, Timesink.Storage.Mux,
    webhook_key: fetch_env!.("TIMESINK_MUX_WEBHOOK_KEY"),
    access_key_id: fetch_env!.("TIMESINK_MUX_ACCESS_KEY_ID"),
    access_key_secret: fetch_env!.("TIMESINK_MUX_ACCESS_KEY_SECRET")

  # Stripe (prod)
  config :timesink, :stripe,
    secret_key: fetch_env!.("TIMESINK_STRIPE_SECRET_KEY"),
    publishable_key: fetch_env!.("TIMESINK_STRIPE_PUBLISHABLE_KEY")

  config :stripity_stripe,
    api_key: fetch_env!.("TIMESINK_STRIPE_SECRET_KEY")

  # BTC Pay (prod)
  config :timesink, :btc_pay,
    api_key: fetch_env!.("TIMESINK_BTC_PAY_API_KEY"),
    url: fetch_env!.("TIMESINK_BTC_PAY_API_URL"),
    store_id: fetch_env!.("TIMESINK_BTC_PAY_STORE_ID"),
    webhook_secret: fetch_env!.("TIMESINK_BTC_PAY_WEBHOOK_SECRET"),
    webhook_url: fetch_env!.("TIMESINK_BTC_PAY_WEBHOOK_URL")
end
