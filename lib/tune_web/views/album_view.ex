defmodule TuneWeb.AlbumView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Album, Artist, Player, Track}

  @default_artwork "https://via.placeholder.com/300"

  @spec artwork(Album.t()) :: String.t()
  defp artwork(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  @spec playing_track?(Track.t(), Player.t()) :: boolean()
  defp playing_track?(%Track{id: track_id}, %Player{status: :playing, item: %{id: track_id}}),
    do: true

  defp playing_track?(_track, _now_playing), do: false

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

  @spec last_fm_track_link(Track.t(), Album.t(), Artist.t()) :: String.t()
  def last_fm_track_link(track, album, artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name),
      URI.encode(album.name),
      URI.encode(track.name)
    ])
  end
end
