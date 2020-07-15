defmodule TuneWeb.Router do
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

  scope "/auth", TuneWeb do
    pipe_through :browser

    get "/logout", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    post "/logout", AuthController, :delete
  end

  scope "/", TuneWeb do
    pipe_through :browser

    live "/", ExplorerLive, :index
    live "/artists/:artist_id", ExplorerLive, :show_artist
    live "/albums/:album_id", ExplorerLive, :show_album
    live "/shows/:show_id", ExplorerLive, :show_show
  end

  # Other scopes may use custom stacks.
  # scope "/api", TuneWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: TuneWeb.Telemetry,
        metrics_history: {TuneWeb.Telemetry.Storage, :metrics_history, []}
    end
  end
end
