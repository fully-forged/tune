defmodule Tune.Spotify.Session.Worker do
  use GenStateMachine
  @behaviour Tune.Spotify.Session

  alias Tune.Spotify.{HttpApi, SessionRegistry}

  defstruct session_id: nil,
            credentials: nil,
            user: nil,
            now_playing: :not_playing

  @now_playing_refresh_interval 2000
  @retry_interval 5000

  def start_link({session_id, credentials}), do: start_link(session_id, credentials)

  def start_link(session_id, credentials) do
    GenStateMachine.start_link(__MODULE__, {session_id, credentials}, name: via(session_id))
  end

  @impl true
  def setup(session_id, credentials) do
    Tune.Spotify.Supervisor.ensure_session(session_id, credentials)
  end

  @impl true
  def get_profile(session_id) do
    GenStateMachine.call(via(session_id), :get_profile)
  end

  @impl true
  def now_playing(session_id) do
    GenStateMachine.call(via(session_id), :now_playing)
  end

  @impl true
  def toggle_play(session_id) do
    GenStateMachine.call(via(session_id), :toggle_play)
  end

  @impl true
  def play(session_id, uri) do
    GenStateMachine.call(via(session_id), {:play, uri})
  end

  @impl true
  def next(session_id) do
    GenStateMachine.call(via(session_id), :next)
  end

  @impl true
  def prev(session_id) do
    GenStateMachine.call(via(session_id), :prev)
  end

  @impl true
  def search(session_id, q, types) do
    GenStateMachine.call(via(session_id), {:search, q, types})
  end

  @impl true
  def init({session_id, credentials}) do
    data = %__MODULE__{session_id: session_id, credentials: credentials}
    action = {:next_event, :internal, :authenticate}
    {:ok, :not_authenticated, data, action}
  end

  @impl true
  def handle_event(event_type, :authenticate, :not_authenticated, data)
      when event_type in [:internal, :state_timeout] do
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

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, @retry_interval, :authenticate}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(event_type, :refresh, :expired, data)
      when event_type in [:internal, :state_timeout] do
    case HttpApi.get_token(data.credentials.refresh_token) do
      {:ok, new_credentials} ->
        data = %{data | credentials: new_credentials}
        action = {:next_event, :internal, :authenticate}
        {:next_state, :not_authenticated, data, action}

      {:error, status} when is_integer(status) ->
        {:stop, :invalid_refresh_token}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, @retry_interval, :refresh}
        {:keep_state_and_data, action}
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

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, @retry_interval, :get_now_playing}
        {:keep_state_and_data, action}

      now_playing ->
        if data.now_playing !== now_playing do
          Tune.Spotify.Session.broadcast(data.session_id, now_playing)
        end

        data = %{data | now_playing: now_playing}

        action = {:state_timeout, @now_playing_refresh_interval, :get_now_playing}
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

  def handle_event(
        {:call, from},
        :toggle_play,
        :authenticated,
        %{now_playing: {:playing, _item}} = data
      ) do
    case HttpApi.pause(data.credentials.token) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}
    end
  end

  def handle_event(
        {:call, from},
        :toggle_play,
        :authenticated,
        %{now_playing: {:paused, _item}} = data
      ) do
    case HttpApi.play(data.credentials.token) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}
    end
  end

  def handle_event(
        {:call, from},
        :toggle_play,
        :authenticated,
        _data
      ) do
    action = {:reply, from, :ok}
    {:keep_state_and_data, action}
  end

  def handle_event(
        {:call, from},
        {:search, q, types},
        :authenticated,
        data
      ) do
    case HttpApi.search(data.credentials.token, q, types) do
      {:ok, results} ->
        action = {:reply, from, {:ok, results}}
        {:keep_state_and_data, action}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      # abnormal http error
      error ->
        action = {:reply, from, error}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(
        {:call, from},
        {:play, uri},
        :authenticated,
        data
      ) do
    case HttpApi.play(data.credentials.token, uri) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      # abnormal http error
      error ->
        action = {:reply, from, error}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(
        {:call, from},
        :next,
        :authenticated,
        data
      ) do
    case HttpApi.next(data.credentials.token) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      # abnormal http error
      error ->
        action = {:reply, from, error}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(
        {:call, from},
        :prev,
        :authenticated,
        data
      ) do
    case HttpApi.prev(data.credentials.token) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      # abnormal http error
      error ->
        action = {:reply, from, error}
        {:keep_state_and_data, action}
    end
  end

  def handle_event({:call, from}, _request, _state, _data) do
    action = {:reply, from, {:error, :not_authenticated}}
    {:keep_state_and_data, action}
  end

  defp via(token) do
    {:via, Registry, {SessionRegistry, token}}
  end
end
