defmodule Tune.Spotify.Schema.Album do
  @moduledoc false

  @enforce_keys [
    :id,
    :uri,
    :name,
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
    :artist,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]

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
end
