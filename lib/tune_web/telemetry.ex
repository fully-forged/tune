defmodule TuneWeb.Telemetry do
  @moduledoc false
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Tune Metrics
      summary("tune.session.count.active"),
      summary("tune.spotify.api_error.count",
        tags: [:error_type]
      ),

      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.live_view.mount.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.live_view.handle_params.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.live_view.handle_event.stop.duration",
        unit: {:native, :millisecond},
        tags: [:event]
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # HTTP - Spotify
      summary("finch.request.stop.duration",
        unit: {:native, :millisecond},
        tags: [:normalized_path],
        tag_values: &add_normalized_path/1,
        keep: &keep_spotify/1,
        reporter_options: [
          nav: "HTTP - Spotify"
        ]
      ),
      summary("finch.response.stop.duration",
        unit: {:native, :millisecond},
        tags: [:normalized_path],
        tag_values: &add_normalized_path/1,
        keep: &keep_spotify/1,
        reporter_options: [
          nav: "HTTP - Spotify"
        ]
      )
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      {Tune.Spotify.Supervisor, :count_sessions, []}
    ]
  end

  defp add_normalized_path(metadata) do
    Map.put(metadata, :normalized_path, URI.parse(metadata.path).path)
  end

  defp keep_spotify(meta) do
    meta.host =~ "spotify"
  end
end
