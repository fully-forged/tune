defmodule TuneWeb.SearchView do
  use TuneWeb, :view

  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema.{Album, Artist, Episode, Show, Track}

  defp thumbnail(%Track{album: album}),
    do: resolve_thumbnail(album.thumbnails, [:medium, :large])

  defp thumbnail(%Album{thumbnails: thumbnails}),
    do: resolve_thumbnail(thumbnails, [:medium, :large])

  defp thumbnail(%Artist{thumbnails: thumbnails}),
    do: resolve_thumbnail(thumbnails, [:medium, :large])

  defp thumbnail(%Show{thumbnails: thumbnails}),
    do: resolve_thumbnail(thumbnails, [:medium, :large])

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: resolve_thumbnail(thumbnails, [:medium, :large])

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

  defp resolve_thumbnail(thumbnails, preferred_sizes) do
    Enum.find_value(thumbnails, @default_medium_thumbnail, fn {size, url} ->
      if size in preferred_sizes, do: url
    end)
  end
end
