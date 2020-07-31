defmodule TuneWeb.ArtistView do
  @moduledoc false
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"
  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema.{Album, Artist}

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

  @spec thumbnail(Album.t()) :: String.t()
  defp thumbnail(%Album{thumbnails: thumbnails}) do
    Enum.find_value(thumbnails, @default_medium_thumbnail, fn {size, url} ->
      if size in [:medium, :large], do: url
    end)
  end
end
