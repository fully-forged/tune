defmodule TuneWeb.PlayerView do
  @moduledoc false
  use TuneWeb, :view

  @default_small_thumbnail "https://via.placeholder.com/48"

  alias Tune.Spotify.Schema.{Episode, Track}

  @spec thumbnail(Track.t() | Episode.t()) :: String.t()
  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :small, @default_small_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :small, @default_small_thumbnail)

  @spec name(Track.t() | Episode.t()) :: String.t()
  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name

  @spec author_name(Track.t() | Episode.t()) :: String.t()
  defp author_name(%Track{artist: artist}), do: artist.name
  defp author_name(%Episode{publisher: publisher}), do: publisher.name

  @spec author_link(Track.t() | Episode.t(), Phoenix.Socket.t()) :: nil | String.t()
  defp author_link(%Track{artist: artist}, socket) do
    TuneWeb.SearchView.result_link(artist, socket)
  end

  defp author_link(%Episode{}, _socket), do: nil
end
