defmodule TuneWeb.PlaylistView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.Playlist
  alias TuneWeb.{PlayerView, SearchView}

  @default_artwork "https://via.placeholder.com/300"

  @spec artwork(Playlist.t()) :: String.t()
  defp artwork(playlist),
    do: Map.get(playlist.thumbnails, :large, @default_artwork)

  defp group_label("single"), do: "Singles"
  defp group_label("album"), do: "Albums"
  defp group_label(other), do: other

  @spec total_duration(Playlist.t()) :: String.t()
  defp total_duration(playlist) do
    formatted_duration =
      playlist
      |> Playlist.total_duration_ms()
      |> Tune.Duration.human()

    tracks_count = Playlist.tracks_count(playlist)

    ngettext(
      "1 track, %{formatted_duration}",
      "%{count} tracks, %{formatted_duration}",
      tracks_count,
      %{formatted_duration: formatted_duration}
    )
  end
end
