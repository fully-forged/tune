defmodule TuneWeb.PlaylistView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.Playlist
  alias TuneWeb.{PlayerView, SearchView}

  @default_artwork "https://via.placeholder.com/300"

  @spec artwork(Playlist.t()) :: String.t()
  defp artwork(playlist),
    do: Map.get(playlist.thumbnails, :large, @default_artwork)

  defp group_label("single"), do: "Singles"
  defp group_label("album"), do: "Albums"
  defp group_label(other), do: other
end
