defmodule Tune.Spotify.Session do
  use GenServer
  @behaviour Tune.Spotify

  alias Tune.Spotify.{HttpApi, SessionRegistry}

  defstruct user: nil,
            now_playing: :not_playing

  def start_link(token) do
    GenServer.start_link(__MODULE__, token, name: via(token))
  end

  def setup(token) do
    Tune.Spotify.Supervisor.ensure_session(token)
  end

  def get_profile(token) do
    GenServer.call(via(token), :get_profile)
  end

  def now_playing(token) do
    GenServer.call(via(token), :now_playing)
  end

  def init(token) do
    case HttpApi.get_profile(token) do
      {:ok, user} ->
        {:ok, %__MODULE__{user: user}}

      _error ->
        {:stop, :invalid_token}
    end
  end

  def handle_call(:get_profile, _from, state) do
    {:reply, state.user, state}
  end

  def handle_call(:now_playing, _from, state) do
    {:reply, state.now_playing, state}
  end

  defp via(token) do
    {:via, Registry, {SessionRegistry, token}}
  end
end
