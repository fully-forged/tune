defmodule TuneWeb.ArtistView do
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"

  alias Tune.Spotify.Schema.Artist

  defp artwork(%Artist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)
end
