defmodule TuneWeb.SuggestionsView do
  @moduledoc false
  use TuneWeb, :view

  @default_artwork "https://via.placeholder.com/300"

  alias Tune.Spotify.Schema.Playlist
  alias TuneWeb.SearchView

  @spec artwork(Playlist.t()) :: String.t()
  defp artwork(%Playlist{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :large, @default_artwork)

  defp group_label("single"), do: "Singles"
  defp group_label("album"), do: "Albums"
  defp group_label(other), do: other
end
