defmodule TuneWeb.SearchView do
  use TuneWeb, :view

  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema.{Album, Artist, Episode, Show, Track}

  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :medium, @default_medium_thumbnail)

  defp thumbnail(%Album{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_medium_thumbnail)

  defp thumbnail(%Artist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_medium_thumbnail)

  defp thumbnail(%Show{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_medium_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :medium, @default_medium_thumbnail)

  defp name(%Track{name: name}), do: name
  defp name(%Album{name: name}), do: name
  defp name(%Show{name: name}), do: name
  defp name(%Artist{name: name}), do: name
  defp name(%Episode{name: name}), do: name

  defp author_name(%Track{artist: artist}), do: artist.name
  defp author_name(%Album{artist: artist}), do: artist.name
  defp author_name(%Show{publisher: publisher}), do: publisher.name
  defp author_name(%Artist{}), do: ""
  defp author_name(%Episode{}), do: ""
end
