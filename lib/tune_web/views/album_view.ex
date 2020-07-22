defmodule TuneWeb.AlbumView do
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Album, Player}

  @default_artwork "https://via.placeholder.com/300"

  defp artwork(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  defp grouped_tracks(%Album{tracks: tracks}) do
    Enum.group_by(tracks, & &1.disc_number)
  end

  defp has_multiple_discs?(%Album{tracks: tracks}) do
    disc_numbers =
      tracks
      |> Enum.map(& &1.disc_number)
      |> Enum.into(MapSet.new())

    MapSet.size(disc_numbers) > 1
  end

  defp playing_track?(%{id: track_id}, %Player{status: :playing, item: %{id: track_id}}), do: true
  defp playing_track?(_track, _now_playing), do: false

  defp total_duration(album) do
    formatted_duration =
      album
      |> Album.total_duration_ms()
      |> Tune.Duration.human()

    tracks_count = Album.tracks_count(album)

    "#{tracks_count} track(s), #{formatted_duration}"
  end

  def last_fm_track_link(track, album, artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name),
      URI.encode(album.name),
      URI.encode(track.name)
    ])
  end
end
