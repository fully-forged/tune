defmodule TuneWeb.SearchView do
  @moduledoc false
  use TuneWeb, :view

  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema
  alias Schema.{Album, Artist, Episode, Show, Track}

  @type result_item() :: Album.t() | Artist.t() | Episode.t() | Show.t() | Track.t()

  @spec name(result_item()) :: String.t()
  def name(%Track{name: name}), do: name
  def name(%Album{name: name}), do: name
  def name(%Show{name: name}), do: name
  def name(%Artist{name: name}), do: name
  def name(%Episode{name: name}), do: name

  @spec authors(result_item(), Phoenix.Socket.t()) :: [{String.t(), nil | String.t()}]
  defp authors(%Episode{publisher: publisher}, _socket) do
    publisher.name
  end

  defp authors(%Track{artists: artists}, socket) do
    artists
    |> Enum.map(fn artist ->
      live_patch(artist.name, to: Routes.explorer_path(socket, :artist_details, artist.id))
    end)
    |> Enum.intersperse(", ")
  end

  defp authors(%Album{artists: artists}, socket) do
    artists
    |> Enum.map(fn artist ->
      live_patch(artist.name, to: Routes.explorer_path(socket, :artist_details, artist.id))
    end)
    |> Enum.intersperse(", ")
  end

  defp authors(%Show{publisher: publisher}, _socket) do
    publisher.name
  end

  defp authors(%Artist{}, _socket), do: nil

  @spec result_link(result_item(), Phoenix.Socket.t()) :: String.t()
  def result_link(%Track{album: album}, socket) do
    Routes.explorer_path(socket, :album_details, album.id)
  end

  def result_link(%Album{id: id}, socket) do
    Routes.explorer_path(socket, :album_details, id)
  end

  def result_link(%Show{id: id}, socket) do
    Routes.explorer_path(socket, :show_details, id)
  end

  def result_link(%Episode{id: id}, socket) do
    Routes.explorer_path(socket, :episode_details, id)
  end

  def result_link(%Artist{id: id}, socket) do
    Routes.explorer_path(socket, :artist_details, id)
  end

  def can_link_to_author?(%Track{}), do: true
  def can_link_to_author?(%Album{}), do: true
  def can_link_to_author?(_other), do: false

  def release_date(%Track{album: album}) do
    Album.release_year(album)
  end

  def release_date(%Album{} = album) do
    Album.release_year(album)
  end

  def release_date(_other), do: nil

  @spec thumbnail(result_item()) :: String.t()
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

  @spec resolve_thumbnail(Schema.thumbnails(), [Schema.thumbnail_size()]) :: String.t()
  defp resolve_thumbnail(thumbnails, preferred_sizes) do
    Enum.find_value(thumbnails, @default_medium_thumbnail, fn {size, url} ->
      if size in preferred_sizes, do: url
    end)
  end
end
