defmodule Tune.Spotify.Schema.Album do
  @moduledoc """
  Represents an album.

  Depending on how the album is retrieved, it may or may not include an artist or tracks.
  """

  alias Tune.Spotify.Schema
  alias Schema.{Artist, Track}

  @enforce_keys [
    :id,
    :uri,
    :name,
    :album_type,
    :album_group,
    :artist,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]
  defstruct [
    :id,
    :uri,
    :name,
    :album_type,
    :album_group,
    :artist,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]

  @type t :: %__MODULE__{
          id: Schema.id(),
          uri: Schema.uri(),
          name: String.t(),
          album_type: String.t(),
          album_group: String.t(),
          artist: Artist.t() | :not_fetched,
          release_date: String.t(),
          release_date_precision: String.t(),
          thumbnails: Schema.thumbnails(),
          tracks: [Track.t()] | :not_fetched
        }

  def total_duration_ms(album) do
    case album.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.reduce(tracks, 0, fn track, total_duration_ms ->
          total_duration_ms + track.duration_ms
        end)
    end
  end

  def tracks_count(album) do
    case album.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.count(tracks)
    end
  end

  def release_year(album) do
    case album.release_date_precision do
      "year" ->
        album.release_date

      _other ->
        {year, _rest} = String.split_at(album.release_date, 4)
        year
    end
  end
end
