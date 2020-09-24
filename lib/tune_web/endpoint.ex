defmodule TuneWeb.Endpoint do
  @moduledoc false
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :tune

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_tune_key",
    signing_salt: "2txYZyfx",
    encryption_salt: {__MODULE__, :config, [:session_encryption_salt]},
    same_site: "Lax"
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
    only_matching: ~w(css fonts images js favicon robots)

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

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TuneWeb.Router

  def init(_type, config) do
    %{web: runtime_overrides} = Vapor.load!(Tune.Config)

    config =
      Keyword.merge(config,
        secret_key_base: runtime_overrides.secret_key_base,
        admin_user: runtime_overrides.admin_user,
        admin_password: runtime_overrides.admin_password,
        session_encryption_salt: runtime_overrides.session_encryption_salt
      )

    if runtime_overrides.port do
      {:ok,
       Keyword.put(
         config,
         :http,
         port: runtime_overrides.port,
         transport_options: [socket_opts: [:inet6]]
       )}
    else
      {:ok, config}
    end
  end
end
