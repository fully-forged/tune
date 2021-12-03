defmodule TuneWeb.PlaylistView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema
  alias Schema.Playlist
  alias TuneWeb.{PlayerView, SearchView}

  @default_artwork "https://via.placeholder.com/300"

  @spec artwork(Playlist.t()) :: String.t()
  defp artwork(playlist),
    do: resolve_thumbnail(playlist.thumbnails, [:medium, :large])

  defp group_label("single"), do: gettext("Singles")
  defp group_label("album"), do: gettext("Albums")
  defp group_label("compilation"), do: gettext("Compilations")
  defp group_label(other), do: other

  @spec total_duration(Playlist.t()) :: String.t()
  defp total_duration(playlist) do
    formatted_duration =
      playlist
      |> Playlist.total_duration_ms()
      |> Tune.Duration.human()

    tracks_count = Playlist.tracks_count(playlist)

    ngettext(
      "1 track, %{formatted_duration}",
      "%{count} tracks, %{formatted_duration}",
      tracks_count,
      %{formatted_duration: formatted_duration}
    )
  end

  @spec resolve_thumbnail(Schema.thumbnails(), [Schema.thumbnail_size()]) :: String.t()
  defp resolve_thumbnail(thumbnails, preferred_sizes) do
    Enum.find_value(thumbnails, @default_artwork, fn {size, url} ->
      if size in preferred_sizes, do: url
    end)
  end
end
