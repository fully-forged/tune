defmodule TuneWeb.LiveDashboard.SpotifySessionsPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "Spotify Sessions"}
  end

  @impl true
  def render_page(_assigns) do
    table(
      columns: columns(),
      id: :spotify_sessions,
      row_attrs: &row_attrs/1,
      row_fetcher: &fetch_session_counts/2,
      rows_name: "sessions",
      title: "Spotify Sessions"
    )
  end

  defp fetch_session_counts(params, node) do
    clients_count =
      node
      |> :rpc.call(Tune.Spotify.Supervisor, :clients_count, [])
      |> filter(params)

    {clients_count, length(clients_count)}
  end

  defp columns do
    [
      %{field: :id, header: "Session ID", sortable: :asc},
      %{
        field: :pid,
        header: "Worker PID",
        format: &(&1 |> encode_pid() |> String.replace_prefix("PID", ""))
      },
      %{field: :clients_count, header: "Clients count", sortable: :asc}
    ]
  end

  defp row_attrs(table) do
    [
      {"phx-click", "show_info"},
      {"phx-value-info", encode_pid(table[:pid])},
      {"phx-page-loading", true}
    ]
  end

  defp filter(clients_count, _params) do
    clients_count
  end
end
