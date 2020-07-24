defmodule TuneWeb.ArtistView do
  @moduledoc false
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"

  alias Tune.Spotify.Schema.Artist

  @spec artwork(Artist.t()) :: String.t()
  defp artwork(%Artist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  @spec wikipedia_link(Artist.t()) :: String.t()
  defp wikipedia_link(artist) do
    Path.join([
      "https://en.wikipedia.org/wiki",
      artist.name <> "_(band)"
    ])
  end

  @spec last_fm_link(Artist.t()) :: String.t()
  defp last_fm_link(artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name)
    ])
  end
end
