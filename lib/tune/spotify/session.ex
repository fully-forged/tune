defmodule Tune.Spotify.Session do
  alias Phoenix.PubSub

  @type id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()

  @type q :: String.t()
  @type item_type :: :album | :artist | :playlist | :track | :show | :episode
  @type uri :: String.t()

  @callback setup(id(), credentials()) :: :ok | {:error, term()}
  @callback get_profile(id()) :: {:ok, %Tune.Spotify.Schema.User{}} | {:error, term()}
  @callback now_playing(id()) ::
              :not_playing
              | {:playing | :paused,
                 %Tune.Spotify.Schema.Track{} | %Tune.Spotify.Schema.Episode{}}
              | {:error, term()}
  @callback toggle_play(id()) :: :ok | {:error, term()}
  @callback play(id(), uri()) :: :ok | {:error, term()}
  @callback search(id(), String.t(), [item_type()]) :: {:ok, [map()]} | {:error, term()}

  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
  end

  def broadcast(session_id, message) do
    PubSub.broadcast(Tune.PubSub, session_id, message)
  end
end
