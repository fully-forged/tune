defmodule TuneWeb.AlbumView do
  use TuneWeb, :view

  alias Tune.Spotify.Schema.Album

  @default_artwork "https://via.placeholder.com/300"

  defp artwork(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :large, @default_artwork)
end
