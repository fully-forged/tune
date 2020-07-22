defmodule TuneWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :tune

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_tune_key",
    signing_salt: "2txYZyfx",
    encryption_salt: {__MODULE__, :get_encryption_salt, []}
  ]

  socket "/socket", TuneWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :tune,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TuneWeb.Router

  def init(_type, config) do
    config =
      case System.get_env("PORT") do
        nil ->
          config

        port ->
          new_config = [
            http: [port: port, transport_options: [socket_opts: [:inet6]]],
            secret_key_base: System.get_env("SECRET_KEY_BASE")
          ]

          Keyword.merge(config, new_config)
      end

    {:ok, config}
  end

  def get_encryption_salt do
    System.get_env("SESSION_ENCRYPTION_SALT")
  end
end
