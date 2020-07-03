defmodule Tune.Spotify.Session do
  use GenStateMachine
  @behaviour Tune.Spotify

  alias Tune.Spotify.{HttpApi, SessionRegistry}
  alias Phoenix.PubSub

  defstruct session_id: nil,
            credentials: nil,
            user: nil,
            now_playing: :not_playing

  def start_link({session_id, credentials}), do: start_link(session_id, credentials)

  def start_link(session_id, credentials) do
    GenStateMachine.start_link(__MODULE__, {session_id, credentials}, name: via(session_id))
  end

  def setup(session_id, credentials) do
    Tune.Spotify.Supervisor.ensure_session(session_id, credentials)
  end

  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
  end

  def get_profile(session_id) do
    GenStateMachine.call(via(session_id), :get_profile)
  end

  def now_playing(session_id) do
    GenStateMachine.call(via(session_id), :now_playing)
  end

  def init({session_id, credentials}) do
    data = %__MODULE__{session_id: session_id, credentials: credentials}
    action = {:next_event, :internal, :authenticate}
    {:ok, :not_authenticated, data, action}
  end

  def handle_event(:internal, :authenticate, :not_authenticated, data) do
    case HttpApi.get_profile(data.credentials.token) do
      {:ok, user} ->
        data = %{data | user: user}
        action = {:next_event, :internal, :get_now_playing}
        {:next_state, :authenticated, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}
    end
  end

  def handle_event(:internal, :refresh, :expired, data) do
    case HttpApi.get_token(data.credentials.refresh_token) do
      {:ok, new_credentials} ->
        data = %{data | credentials: new_credentials}
        action = {:next_event, :internal, :authenticate}
        {:next_state, :not_authenticated, data, action}

      {:error, _reason} ->
        {:stop, :invalid_refresh_token}
    end
  end

  def handle_event(event_type, :get_now_playing, :authenticated, data)
      when event_type in [:internal, :state_timeout] do
    case HttpApi.now_playing(data.credentials.token) do
      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      now_playing ->
        if data.now_playing !== now_playing do
          PubSub.broadcast(Tune.PubSub, data.session_id, now_playing)
        end

        data = %{data | now_playing: now_playing}

        action = {:state_timeout, 5000, :get_now_playing}
        {:keep_state, data, action}
    end
  end

  def handle_event({:call, from}, :get_profile, :authenticated, data) do
    action = {:reply, from, data.user}
    {:keep_state_and_data, action}
  end

  def handle_event({:call, from}, :now_playing, :authenticated, data) do
    action = {:reply, from, data.now_playing}
    {:keep_state_and_data, action}
  end

  def handle_event({:call, from}, _request, _state, _data) do
    action = {:reply, from, {:error, :not_authenticated}}
    {:keep_state_and_data, action}
  end

  defp via(token) do
    {:via, Registry, {SessionRegistry, token}}
  end
end