defmodule Tune.Spotify.Session do
  use GenServer
  @behaviour Tune.Spotify

  alias Tune.Spotify.{HttpApi, SessionRegistry}
  alias Phoenix.PubSub

  defstruct token: nil,
            user: nil,
            now_playing: :not_playing

  def start_link(token) do
    GenServer.start_link(__MODULE__, token, name: via(token))
  end

  def subscribe(token) do
    PubSub.subscribe(Tune.PubSub, token)
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
        {:ok, %__MODULE__{user: user, token: token}, {:continue, :get_now_playing}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_call(:get_profile, _from, state) do
    {:reply, state.user, state}
  end

  def handle_call(:now_playing, _from, state) do
    {:reply, state.now_playing, state}
  end

  def handle_continue(:get_now_playing, state) do
    now_playing = HttpApi.now_playing(state.token)

    if state.now_playing !== now_playing do
      PubSub.broadcast(Tune.PubSub, state.token, now_playing)
    end

    Process.send_after(self(), :get_now_playing, 5000)
    {:noreply, %{state | now_playing: now_playing}}
  end

  def handle_info(:get_now_playing, state) do
    handle_continue(:get_now_playing, state)
  end

  defp via(token) do
    {:via, Registry, {SessionRegistry, token}}
  end
end
