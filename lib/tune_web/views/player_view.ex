defmodule TuneWeb.PlayerView do
  use TuneWeb, :view

  @default_small_thumbnail "https://via.placeholder.com/48"

  alias Tune.Spotify.Schema.{Episode, Track}

  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :small, @default_small_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :small, @default_small_thumbnail)

  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name

  defp author_name(%Track{artist: artist}), do: artist.name
  defp author_name(%Episode{publisher: publisher}), do: publisher.name
end
