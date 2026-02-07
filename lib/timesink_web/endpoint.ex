defmodule TimesinkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :timesink
  alias TimesinkWeb.Plugs

  @session_key Application.compile_env(:timesink, :session_cookie_key)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @base_session_options [
    store: :cookie,
    key: @session_key,
    signing_salt: "xfGNS3d0",
    same_site: "Lax"
  ]

  @session_options Keyword.merge(
                     @base_session_options,
                     Application.get_env(:timesink, __MODULE__, [])
                     |> Keyword.get(:session_options, [])
                   )

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :timesink,
    gzip: false,
    only: TimesinkWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :timesink
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug TimesinkWeb.Plugs.CaptureRawBody

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plugs.CanonicalHost
  plug Plug.Session, @session_options
  plug TimesinkWeb.Router
end
