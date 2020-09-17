defmodule Tune.Spotify.Schema.Playlist do
  @moduledoc """
  Represents a playlist.
  """

  alias Tune.{Duration, Spotify.Schema}
  alias Schema.{Album, Track}

  @enforce_keys [
    :id,
    :uri,
    :name,
    :description,
    :thumbnails,
    :tracks
  ]
  defstruct [
    :id,
    :uri,
    :name,
    :description,
    :thumbnails,
    :tracks
  ]

  @type id :: Schema.id()
  @type t :: %__MODULE__{
          id: id(),
          uri: Schema.uri(),
          name: String.t(),
          description: String.t(),
          thumbnails: Schema.thumbnails(),
          tracks: [Track.t()] | :not_fetched
        }

  @spec total_duration_ms(t()) :: Duration.milliseconds() | :not_available
  def total_duration_ms(playlist) do
    case playlist.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.reduce(tracks, 0, fn track, total_duration_ms ->
          total_duration_ms + track.duration_ms
        end)
    end
  end

  @spec tracks_count(t()) :: pos_integer() | :not_available
  def tracks_count(playlist) do
    case playlist.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.count(tracks)
    end
  end

  @spec albums_grouped_by_type(t()) :: %{Album.album_type() => [Album.t()]} | :not_available
  def albums_grouped_by_type(playlist) do
    case playlist.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.group_by(tracks, & &1.album.album_type, & &1.album)
    end
  end
end
