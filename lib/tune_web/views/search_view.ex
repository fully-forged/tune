defmodule TuneWeb.SearchView do
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Album, Artist, Episode, Show, Track}

  defp thumbnail(%Track{album: album}), do: album.thumbnails.medium
  defp thumbnail(%Album{thumbnails: thumbnails}), do: thumbnails.medium
  defp thumbnail(%Artist{thumbnails: thumbnails}), do: thumbnails.medium
  defp thumbnail(%Show{thumbnails: thumbnails}), do: thumbnails.medium
  defp thumbnail(%Episode{thumbnails: thumbnails}), do: thumbnails.medium

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
