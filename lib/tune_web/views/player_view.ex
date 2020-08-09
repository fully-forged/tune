defmodule TuneWeb.PlayerView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Episode, Track}

  @spec name(Track.t() | Episode.t()) :: String.t()
  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name

  @spec authors(Track.t() | Episode.t(), Phoenix.Socket.t()) :: String.t()
  defp authors(%Episode{publisher: publisher}, _socket) do
    publisher.name
  end

  defp authors(%Track{artists: artists}, socket) do
    artists
    |> Enum.map(fn artist ->
      live_patch(artist.name,
        to: Routes.explorer_path(socket, :artist_details, artist.id),
        class: "artist-name reversed"
      )
    end)
    |> Enum.intersperse(", ")
  end
end
