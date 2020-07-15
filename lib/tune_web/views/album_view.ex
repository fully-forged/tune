defmodule TuneWeb.AlbumView do
  use TuneWeb, :view

  alias Tune.Spotify.Schema.Album

  @default_artwork "https://via.placeholder.com/300"

  defp artwork(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :large, @default_artwork)

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
end
