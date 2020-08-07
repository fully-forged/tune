defmodule Tune.Spotify.Session do
  @moduledoc """
  Defines a behaviour that can be used to model an active user session against the Spotify API.
  """
  alias Phoenix.PubSub

  alias Tune.Duration
  alias Tune.Spotify.{HttpApi, Schema}

  @type id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()
  @type player_token :: binary() | nil

  @type uri :: String.t()
  @type context_uri :: String.t()
  @type item_id :: String.t()

  @type message :: {:now_playing, Schema.Player.t()} | {:player_token, player_token()}

  @callback setup(id(), credentials()) :: :ok | {:error, term()}
  @callback get_profile(id()) :: {:ok, Schema.User.t()} | {:error, term()}
  @callback now_playing(id()) :: Schema.Player.t() | {:error, term()}
  @callback toggle_play(id()) :: :ok | {:error, term()}
  @callback play(id(), uri()) :: :ok | {:error, term()}
  @callback play(id(), uri(), context_uri()) :: :ok | {:error, term()}
  @callback next(id()) :: :ok | {:error, term()}
  @callback seek(id(), Duration.milliseconds()) :: :ok | {:error, term()}
  @callback prev(id()) :: :ok | {:error, term()}
  @callback search(id(), HttpApi.q(), HttpApi.search_options()) ::
              {:ok, HttpApi.search_results()} | {:error, term()}
  @callback top_tracks(id(), HttpApi.top_tracks_options()) ::
              {:ok, [Schema.Track.t()]} | {:error, term()}
  @callback get_album(id(), item_id()) :: {:ok, Schema.Album.t()} | {:error, term()}
  @callback get_artist(id(), item_id()) :: {:ok, Schema.Artist.t()} | {:error, term()}
  @callback get_artist_albums(id(), item_id()) ::
              {:ok, %{albums: [Schema.Album.t()], total: pos_integer()}} | {:error, term()}
  @callback get_show(id(), item_id()) :: {:ok, Schema.Show.t()} | {:error, term()}
  @callback get_episodes(id(), item_id()) :: {:ok, [Schema.Episode.t()]} | {:error, term()}
  @callback get_playlist(id(), item_id()) :: {:ok, map()} | {:error, term()}
  @callback get_devices(id()) :: {:ok, [Schema.Device.t()]} | {:error, term()}
  @callback get_recommendations_from_artists(id(), [Schema.Artist.id()]) ::
              {:ok, [Schema.Track.t()]} | {:error, term()}
  @callback get_player_token(id()) :: {:ok, player_token()} | {:error, term()}
  @callback transfer_playback(id(), Schema.Device.id()) :: :ok | {:error, term()}
  @callback set_volume(id(), Schema.Device.volume_percent()) :: :ok | {:error, term()}

  @spec subscribe(id()) :: :ok | {:error, term()}
  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
  end

  @spec broadcast(id(), message()) :: :ok | {:error, term()}
  def broadcast(session_id, message) do
    PubSub.broadcast(Tune.PubSub, session_id, message)
  end
end
