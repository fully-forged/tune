defmodule TuneWeb.AlbumView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.Album
  alias TuneWeb.TrackView

  @default_artwork "https://via.placeholder.com/300"

  @spec artwork(Album.t()) :: String.t()
  defp artwork(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  @spec total_duration(Album.t()) :: String.t()
  defp total_duration(album) do
    formatted_duration =
      album
      |> Album.total_duration_ms()
      |> Tune.Duration.human()

    tracks_count = Album.tracks_count(album)

    ngettext(
      "1 track, %{formatted_duration}",
      "%{count} tracks, %{formatted_duration}",
      tracks_count,
      %{formatted_duration: formatted_duration}
    )
  end

  @spec last_fm_link(Album.t()) :: String.t()
  defp last_fm_link(album) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(album.artist.name),
      URI.encode(album.name)
    ])
  end
end
