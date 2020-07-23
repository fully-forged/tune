defmodule Tune.Spotify.Session do
  @moduledoc false
  alias Phoenix.PubSub

  alias Tune.Spotify.Schema

  @type id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()

  @type q :: String.t()
  @type item_type :: :album | :artist | :playlist | :track | :show | :episode
  @type uri :: String.t()
  @type item_id :: String.t()

  @type search_options :: [{:types, [item_type()]} | {:limit, pos_integer()}]

  @callback setup(id(), credentials()) :: :ok | {:error, term()}
  @callback get_profile(id()) :: {:ok, Schema.User.t()} | {:error, term()}
  @callback now_playing(id()) ::
              :not_playing
              | {:playing | :paused, Schema.Track.t() | Schema.Episode.t()}
              | {:error, term()}
  @callback toggle_play(id()) :: :ok | {:error, term()}
  @callback play(id(), uri()) :: :ok | {:error, term()}
  @callback next(id()) :: :ok | {:error, term()}
  @callback prev(id()) :: :ok | {:error, term()}
  @callback search(id(), q(), search_options()) :: {:ok, [map()]} | {:error, term()}
  @callback get_album(id(), item_id()) :: {:ok, Schema.Album.t()} | {:error, term()}
  @callback get_artist(id(), item_id()) :: {:ok, Schema.Artist.t()} | {:error, term()}
  @callback get_artist_albums(id(), item_id()) :: {:ok, [Schema.Album.t()]} | {:error, term()}
  @callback get_show(id(), item_id()) :: {:ok, Schema.Show.t()} | {:error, term()}

  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
  end

  def broadcast(session_id, message) do
    PubSub.broadcast(Tune.PubSub, session_id, message)
  end
end
