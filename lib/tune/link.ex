defmodule Tune.Link do
  @moduledoc """
  Provides functions to generate integration links from tracks, artists and albums.

  Implementations are extremely naive and rely on building URLs from metadata,
  but there are times when they simply don't work, particularly with titles
  that have suffixes like "2017 remaster" or "feat. another artist name".
  """

  alias Tune.Spotify.Schema.{Album, Artist, Track}

  @spec last_fm(Album.t() | Artist.t()) :: String.t()
  def last_fm(%Album{} = album) do
    artist_name =
      album
      |> Album.main_artist()
      |> Map.fetch!(:name)

    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist_name),
      URI.encode(album.name)
    ])
  end

  def last_fm(%Artist{name: name}) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(name)
    ])
  end

  @spec last_fm(Track.t(), Album.t(), Artist.t()) :: String.t()
  def last_fm(track, album, artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name),
      URI.encode(album.name),
      URI.encode(track.name)
    ])
  end

  @spec youtube(Album.t() | Artist.t()) :: String.t()
  def youtube(%Album{} = album) do
    artist_name =
      album
      |> Album.main_artist()
      |> Map.fetch!(:name)

    q = [search_query: artist_name <> " " <> album.name]
    "https://www.youtube.com/results?" <> URI.encode_query(q)
  end

  def youtube(%Artist{name: name}) do
    q = [search_query: name]
    "https://www.youtube.com/results?" <> URI.encode_query(q)
  end

  @spec youtube(Track.t(), Artist.t()) :: String.t()
  def youtube(track, artist) do
    q = [search_query: artist.name <> " " <> track.name]
    "https://www.youtube.com/results?" <> URI.encode_query(q)
  end

  @spec wikipedia(Artist.t()) :: String.t()
  def wikipedia(artist) do
    Path.join([
      "https://en.wikipedia.org/wiki",
      artist.name <> "_(band)"
    ])
  end

  @spec musixmatch(Track.t(), Artist.t()) :: String.t()
  def musixmatch(track, artist) do
    Path.join([
      "https://www.musixmatch.com/lyrics",
      parameterize(artist.name),
      parameterize(track.name)
    ])
  end

  @unsafe_characters ~w(< > # % { } \( \) | \ ^ ~ [ ] ` ' ’ ")
  defp parameterize(s) do
    s
    |> String.replace(@unsafe_characters, "-")
    |> Slug.slugify(lowercase: false, separator: ?-, ignore: ["-"])
    |> Kernel.||("")
  end
end
