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

  defp row_attrs(session) do
    [
      {"phx-click", "show_info"},
      {"phx-value-info", encode_pid(session[:pid])},
      {"phx-page-loading", true}
    ]
  end

  defp filter(clients_count, params) do
    clients_count
    |> Enum.filter(fn session -> session_match?(session, params[:search]) end)
    |> Enum.sort_by(fn session -> session[params[:sort_by]] end, params[:sort_dir])
    |> Enum.take(params[:limit])
  end

  defp session_match?(_session, nil), do: true
  defp session_match?(session, search_string), do: String.contains?(session[:id], search_string)
end
