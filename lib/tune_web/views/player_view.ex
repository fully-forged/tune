defmodule TuneWeb.PlayerView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Episode, Track}

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
