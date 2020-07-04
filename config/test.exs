use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tune, TuneWeb.Endpoint,
  http: [port: 4002],
  server: false

config :tune,
  spotify: Tune.Spotify.SessionMock

# Print only warnings and errors during test
config :logger, level: :warn
