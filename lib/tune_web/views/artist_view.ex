defmodule TuneWeb.ArtistView do
  @moduledoc false
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"
  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema.{Album, Artist}
  alias Tune.Link
  alias TuneWeb.PaginationView

  @spec artwork(Artist.t()) :: String.t()
  defp artwork(%Artist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_artwork)

  @spec thumbnail(Album.t()) :: String.t()
  defp thumbnail(%Album{thumbnails: thumbnails}) do
    Enum.find_value(thumbnails, @default_medium_thumbnail, fn {size, url} ->
      if size in [:medium, :large], do: url
    end)
  end

  @spec total_albums(Artist.t()) :: String.t()
  defp total_albums(artist) do
    ngettext("1 album", "%{count} albums", artist.total_albums)
  end

  defp album_groups do
    [
      all: gettext("All"),
      album: gettext("Album"),
      single: gettext("Single"),
      appears_on: gettext("Appears On"),
      compilation: gettext("Compilation")
    ]
  end
end
