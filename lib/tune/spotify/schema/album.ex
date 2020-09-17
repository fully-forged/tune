defmodule Tune.Spotify.Schema.Album do
  @moduledoc """
  Represents an album.

  Depending on how the album is retrieved, it may or may not include artists or tracks.
  """

  alias Tune.{Duration, Spotify.Schema}
  alias Schema.{Artist, Track}

  @enforce_keys [
    :id,
    :uri,
    :name,
    :album_type,
    :album_group,
    :artists,
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
    :artists,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]

  @type id :: Schema.id()
  @type album_type :: String.t()
  @type t :: %__MODULE__{
          id: id(),
          uri: Schema.uri(),
          name: String.t(),
          album_type: album_type(),
          album_group: String.t(),
          artists: [Artist.t()] | :not_fetched,
          release_date: String.t(),
          release_date_precision: String.t(),
          thumbnails: Schema.thumbnails(),
          tracks: [Track.t()] | :not_fetched
        }

  @spec main_artist(t()) :: Artist.t()
  def main_artist(album) do
    List.first(album.artists)
  end

  @spec grouped_tracks(t()) :: %{String.t() => [Track.t()]}
  def grouped_tracks(album) do
    Enum.group_by(album.tracks, & &1.disc_number)
  end

  @spec has_multiple_discs?(t()) :: boolean()
  def has_multiple_discs?(album) do
    disc_numbers =
      album.tracks
      |> Enum.map(& &1.disc_number)
      |> Enum.into(MapSet.new())

    MapSet.size(disc_numbers) > 1
  end

  @spec total_duration_ms(t()) :: Duration.milliseconds() | :not_available
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

  @spec tracks_count(t()) :: pos_integer() | :not_available
  def tracks_count(album) do
    case album.tracks do
      :not_fetched ->
        :not_available

      tracks ->
        Enum.count(tracks)
    end
  end

  @spec release_year(t()) :: String.t()
  def release_year(album) do
    case album.release_date_precision do
      "year" ->
        album.release_date

      _other ->
        {year, _rest} = String.split_at(album.release_date, 4)
        year
    end
  end

  @spec from_tracks([Track.t()]) :: [t()]
  def from_tracks(tracks) do
    tracks
    |> Enum.map(& &1.album)
    |> Enum.uniq()
  end
end
