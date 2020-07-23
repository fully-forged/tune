defmodule TuneWeb.ArtistView do
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"

  alias Tune.Spotify.Schema.Artist

  defp artwork(%Artist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  defp wikipedia_link(artist) do
    Path.join([
      "https://en.wikipedia.org/wiki",
      artist.name <> "_(band)"
    ])
  end

  defp last_fm_link(artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name)
    ])
  end
end
