defmodule TuneWeb.Router do
  @moduledoc false
  use TuneWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TuneWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :admin_auth
  end

  import TuneWeb.AuthController, only: [ensure_authenticated: 2]

  pipeline :authenticated do
    plug :ensure_authenticated
  end

  scope "/auth", TuneWeb do
    pipe_through :browser

    get "/login", AuthController, :new
    get "/logout", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    post "/logout", AuthController, :delete
  end

  scope "/", TuneWeb do
    pipe_through [:browser, :authenticated]

    live "/", ExplorerLive, :search
    live "/artists/:artist_id", ExplorerLive, :artist_details
    live "/albums/:album_id", ExplorerLive, :album_details
    live "/shows/:show_id", ExplorerLive, :show_details
  end

  # Other scopes may use custom stacks.
  # scope "/api", TuneWeb do
  #   pipe_through :api
  # end

  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through [:admin, :browser]

    live_dashboard "/dashboard",
      metrics: TuneWeb.Telemetry,
      metrics_history: {TuneWeb.Telemetry.Storage, :metrics_history, []}
  end

  defp admin_auth(conn, _opts) do
    with {user, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
         admin_user <- TuneWeb.Endpoint.config(:admin_user),
         admin_pass <- TuneWeb.Endpoint.config(:admin_password),
         true <- Plug.Crypto.secure_compare(user, admin_user),
         true <- Plug.Crypto.secure_compare(pass, admin_pass) do
      conn
    else
      _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
    end
  end
end
