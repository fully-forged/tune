defmodule Tune.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Tune.Spotify.Auth.configure!()

    children = [
      # Start the Telemetry supervisor
      TuneWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tune.PubSub},
      # Start the Endpoint (http/https)
      TuneWeb.Endpoint,
      # Start a worker by calling: Tune.Worker.start_link(arg)
      {Finch, name: Tune.Finch}
      # {Tune.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tune.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TuneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
