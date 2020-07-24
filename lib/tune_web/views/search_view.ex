defmodule TuneWeb.SearchView do
  @moduledoc false
  use TuneWeb, :view

  @default_medium_thumbnail "https://via.placeholder.com/150"

  alias Tune.Spotify.Schema
  alias Schema.{Album, Artist, Episode, Show, Track}

  @type result_item() :: Album.t() | Artist.t() | Episode.t() | Show.t() | Track.t()

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

  @spec name(result_item()) :: String.t()
  defp name(%Track{name: name}), do: name
  defp name(%Album{name: name}), do: name
  defp name(%Show{name: name}), do: name
  defp name(%Artist{name: name}), do: name
  defp name(%Episode{name: name}), do: name

  @spec author_name(result_item()) :: String.t()
  defp author_name(%Track{artist: artist}), do: artist.name
  defp author_name(%Album{artist: artist}), do: artist.name
  defp author_name(%Show{publisher: publisher}), do: publisher.name
  defp author_name(%Artist{}), do: ""
  defp author_name(%Episode{}), do: ""

  @spec resolve_thumbnail(Schema.thumbnails(), [Schema.thumbnail_size()]) :: String.t()
  defp resolve_thumbnail(thumbnails, preferred_sizes) do
    Enum.find_value(thumbnails, @default_medium_thumbnail, fn {size, url} ->
      if size in preferred_sizes, do: url
    end)
  end

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

  def result_link(%Episode{show: show}, socket) do
    Routes.explorer_path(socket, :show_details, show.id)
  end

  def result_link(%Artist{id: id}, socket) do
    Routes.explorer_path(socket, :artist_details, id)
  end

  def release_date(%Track{album: album}) do
    Album.release_year(album)
  end

  def release_date(%Album{} = album) do
    Album.release_year(album)
  end

  def release_date(_other), do: nil
end
