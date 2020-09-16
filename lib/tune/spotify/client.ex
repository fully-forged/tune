defmodule Tune.Spotify.Client do
  @moduledoc """
  Defines a behaviour that can be used to model a Spotify API client.

  For a working implementation, see `Tune.Spotify.Client.HTTP`.
  """

  alias Tune.Duration

  alias Tune.Spotify.Schema.{
    Album,
    Artist,
    Device,
    Episode,
    Player,
    Playlist,
    Show,
    Track,
    User
  }

  alias Ueberauth.Auth.Credentials

  @type token :: String.t()
  @type q :: String.t()
  @type item_type :: :album | :artist | :playlist | :track | :show | :episode | :playlist
  @type pagination_option :: {:limit, pos_integer()} | {:offset, pos_integer()}
  @type pagination_options :: [pagination_option()]
  @type search_options :: [{:types, [item_type()]} | pagination_option()]
  @type search_results :: %{
          optional(item_type()) => %{
            total: pos_integer(),
            items:
              [Artist.t()]
              | [Album.t()]
              | [Track.t()]
              | [Show.t()]
              | [Episode.t()]
              | [Playlist.t()]
          }
        }
  @type top_tracks_options :: [{:time_range, String.t()} | pagination_option()]

  ## AUTH/PROFILE
  @callback get_profile(token()) :: {:ok, User.t()} | {:error, term()}
  @callback get_token(token()) :: {:ok, Credentials.t()} | {:error, term()}

  ## PLAYER
  @callback get_devices(token()) :: {:ok, [Device.t()]} | {:error, term()}
  @callback next(token()) :: :ok | {:error, term()}
  @callback now_playing(token()) :: {:ok, Player.t()} | {:error, term()}
  @callback pause(token()) :: :ok | {:error, term()}
  @callback play(token()) :: :ok | {:error, term()}
  @callback play(token(), String.t()) :: :ok | {:error, term()}
  @callback play(token(), String.t(), String.t()) :: :ok | {:error, term()}
  @callback prev(token()) :: :ok | {:error, term()}
  @callback seek(token(), Duration.milliseconds()) :: :ok | {:error, term()}
  @callback set_volume(token(), Device.volume_percent()) :: :ok | {:error, term()}
  @callback transfer_playback(token(), Device.id()) :: :ok | {:error, term()}

  ## CONTENT
  @callback get_album(token(), String.t()) :: {:ok, Album.t()} | {:error, term()}
  @callback get_artist(token(), String.t()) :: {:ok, Artist.t()} | {:error, term()}
  @callback get_artist_albums(token(), String.t(), pagination_options()) ::
              {:ok, %{albums: [Album.t()], total: pos_integer()}} | {:error, term()}
  @callback get_episodes(token(), String.t()) :: {:ok, [Episode.t()]} | {:error, term()}
  @callback get_playlist(token(), String.t()) :: {:ok, map()} | {:error, term()}
  @callback get_recommendations_from_artists(token(), [Artist.id()]) ::
              {:ok, [Track.t()]} | {:error, term()}
  @callback get_show(token(), String.t()) :: {:ok, Show.t()} | {:error, term()}
  @callback search(token(), q(), search_options()) :: {:ok, search_results()} | {:error, term()}
  @callback top_tracks(token(), top_tracks_options()) :: {:ok, [Track.t()]} | {:error, term()}
end
