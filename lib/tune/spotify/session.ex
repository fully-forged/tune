defmodule Tune.Spotify.Session do
  @moduledoc """
  Defines a behaviour that can be used to model an active user session against the Spotify API.
  """
  alias Phoenix.PubSub

  alias Tune.Duration
  alias Tune.Spotify.{HttpApi, Schema}

  @type id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()

  @type uri :: String.t()
  @type item_id :: String.t()

  @callback setup(id(), credentials()) :: :ok | {:error, term()}
  @callback get_profile(id()) :: {:ok, Schema.User.t()} | {:error, term()}
  @callback now_playing(id()) :: Schema.Player.t() | {:error, term()}
  @callback toggle_play(id()) :: :ok | {:error, term()}
  @callback play(id(), uri()) :: :ok | {:error, term()}
  @callback next(id()) :: :ok | {:error, term()}
  @callback seek(id(), Duration.milliseconds()) :: :ok | {:error, term()}
  @callback prev(id()) :: :ok | {:error, term()}
  @callback search(id(), HttpApi.q(), HttpApi.search_options()) ::
              {:ok, HttpApi.search_results()} | {:error, term()}
  @callback get_album(id(), item_id()) :: {:ok, Schema.Album.t()} | {:error, term()}
  @callback get_artist(id(), item_id()) :: {:ok, Schema.Artist.t()} | {:error, term()}
  @callback get_artist_albums(id(), item_id()) :: {:ok, [Schema.Album.t()]} | {:error, term()}
  @callback get_show(id(), item_id()) :: {:ok, Schema.Show.t()} | {:error, term()}

  @spec subscribe(id()) :: :ok | {:error, term()}
  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
  end

  @spec broadcast(id(), term()) :: :ok | {:error, term()}
  def broadcast(session_id, message) do
    PubSub.broadcast(Tune.PubSub, session_id, message)
  end
end
