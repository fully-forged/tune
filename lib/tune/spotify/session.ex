defmodule Tune.Spotify.Session do
  @moduledoc """
  Defines a behaviour that can be used to model an active user session against the Spotify API.

  Implementations should be stateful: given an initial session id and
  authentication credentials, the implementation should perform authentication
  in `c:setup/2`. If successful, a session should be opened and used for any
  other function keyed by the same session id.

  Most of the behaviour functions cover the Spotify HTTP Api and return structs
  defined under `Tune.Spotify.Schema`.

  Two extra functions, `c:subscribe/1` and `c:broadcast/2`, are used to define
  the mechanism used to notify other processes of changes in the session state.

  For a working implementation, see `Tune.Spotify.Session.HTTP`.
  """
  alias Tune.Duration
  alias Tune.Spotify.{Client, Schema}

  @type id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()
  @type player_token :: binary() | nil

  @type uri :: String.t()
  @type context_uri :: String.t()
  @type item_id :: String.t()

  @type message ::
          {:now_playing, Schema.Player.t()}
          | {:player_token, player_token()}
          | {:devices, [Schema.Device.t()]}

  ## AUTH/PROFILE
  @callback get_profile(id()) :: {:ok, Schema.User.t()} | {:error, term()}
  @callback setup(id(), credentials()) :: :ok | {:error, term()}

  ## PLAYER
  @callback get_devices(id()) :: {:ok, [Schema.Device.t()]} | {:error, term()}
  @callback get_player_token(id()) :: {:ok, player_token()} | {:error, term()}
  @callback next(id()) :: :ok | {:error, term()}
  @callback now_playing(id()) :: Schema.Player.t() | {:error, term()}
  @callback play(id(), uri()) :: :ok | {:error, term()}
  @callback play(id(), uri(), context_uri()) :: :ok | {:error, term()}
  @callback prev(id()) :: :ok | {:error, term()}
  @callback refresh_devices(id()) :: :ok | {:error, term()}
  @callback seek(id(), Duration.milliseconds()) :: :ok | {:error, term()}
  @callback set_volume(id(), Schema.Device.volume_percent()) :: :ok | {:error, term()}
  @callback toggle_play(id()) :: :ok | {:error, term()}
  @callback transfer_playback(id(), Schema.Device.id()) :: :ok | {:error, term()}

  ## SEARCH
  @callback search(id(), Client.q(), Client.search_options()) ::
              {:ok, Client.search_results()} | {:error, term()}

  ## CONTENT
  @callback get_album(id(), item_id()) :: {:ok, Schema.Album.t()} | {:error, term()}
  @callback get_artist(id(), item_id()) :: {:ok, Schema.Artist.t()} | {:error, term()}
  @callback get_artist_albums(id(), item_id(), Client.pagination_options()) ::
              {:ok, %{albums: [Schema.Album.t()], total: pos_integer()}} | {:error, term()}
  @callback get_episodes(id(), item_id()) :: {:ok, [Schema.Episode.t()]} | {:error, term()}
  @callback get_playlist(id(), item_id()) :: {:ok, map()} | {:error, term()}
  @callback get_recommendations_from_artists(id(), [Schema.Artist.id()]) ::
              {:ok, [Schema.Track.t()]} | {:error, term()}
  @callback get_show(id(), item_id()) :: {:ok, Schema.Show.t()} | {:error, term()}
  @callback top_tracks(id(), Client.top_tracks_options()) ::
              {:ok, [Schema.Track.t()]} | {:error, term()}

  ## SUBSCRIPTIONS
  @callback broadcast(id(), message()) :: :ok | {:error, term()}
  @callback subscribe(id()) :: :ok | {:error, term()}
end
