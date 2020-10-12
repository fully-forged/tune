defmodule Tune.MixProject do
  use Mix.Project

  def project do
    [
      app: :tune,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      dialyzer: dialyzer(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Tune.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.3"},
      {:phoenix_live_view, "~> 0.14.3"},
      {:phoenix_html, "~> 2.11"},
      {:gettext, "~> 0.11"},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:circular_buffer, "~> 0.3.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ueberauth_spotify, "~> 0.2.1"},
      {:finch, "~> 0.4.0"},
      {:gen_state_machine, "~> 2.1"},
      {:vapor, "~> 0.10.0"},
      {:anonymous_name_generator, "~> 0.1.3"},
      {:slugify, "~> 1.3"},
      {:sentry, "~> 8.0"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.0.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5.0-rc.4", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:stream_data, "~> 0.5.0", only: :test},
      {:eventually, "~> 1.1", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      before_closing_body_tag: &monospace_stylesheet/1,
      nest_modules_by_prefix: [Tune.Spotify.Schema, Tune.Spotify.Session, Tune.Spotify.Client],
      groups_for_modules: [
        "Spotify Schemas": ~r/Schema/,
        "Spotify Session": ~r/Session/,
        "Spotify Client API": ~r/Client/,
        Authentication: ~r/Auth/,
        UI: TuneWeb.ExplorerLive,
        Routing: TuneWeb.Router.Helpers,
        Core: [Tune.Config, Tune.Gettext, Tune.Duration]
      ]
    ]
  end

  defp monospace_stylesheet(:html) do
    """
    <style>
      .content-inner code {
        font-family: IBM Plex Mono, Fira Code, Inconsolata,Menlo,Courier,monospace;
      }
    </style>
    """
  end

  defp monospace_stylesheet(:epub), do: nil
end
