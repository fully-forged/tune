defmodule Tune.Spotify.Session.Worker do
  @moduledoc """
  This module implements a worker that maps to an active user session, wrapping
  interaction with the Spotify API.

  The state machine of the worker handles authentication errors and
  automatically refreshes credentials once expired.
  """

  use GenStateMachine
  @behaviour Tune.Spotify.Session

  alias Tune.Spotify.{HttpApi, Session, SessionRegistry}

  defstruct session_id: nil,
            credentials: nil,
            user: nil,
            now_playing: :not_playing

  @now_playing_refresh_interval 1000
  @retry_interval 5000

  @spec start_link({Session.id(), Session.credentials()}) :: {:ok, pid()} | {:error, term()}
  def start_link({session_id, credentials}), do: start_link(session_id, credentials)

  @spec start_link(Session.id(), Session.credentials()) :: {:ok, pid()} | {:error, term()}
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
  def seek(session_id, position_ms) do
    GenStateMachine.call(via(session_id), {:seek, position_ms})
  end

  @impl true
  def search(session_id, q, opts) do
    GenStateMachine.call(via(session_id), {:search, q, opts})
  end

  @impl true
  def top_tracks(session_id, opts) do
    GenStateMachine.call(via(session_id), {:top_tracks, opts})
  end

  @impl true
  def get_album(session_id, album_id) do
    GenStateMachine.call(via(session_id), {:get_album, album_id})
  end

  @impl true
  def get_artist(session_id, artist_id) do
    GenStateMachine.call(via(session_id), {:get_artist, artist_id})
  end

  @impl true
  def get_artist_albums(session_id, artist_id) do
    GenStateMachine.call(via(session_id), {:get_artist_albums, artist_id})
  end

  @impl true
  def get_show(session_id, show_id) do
    GenStateMachine.call(via(session_id), {:get_show, show_id})
  end

  @impl true
  def get_episodes(session_id, show_id) do
    GenStateMachine.call(via(session_id), {:get_episodes, show_id})
  end

  @impl true
  def get_playlist(session_id, playlist_id) do
    GenStateMachine.call(via(session_id), {:get_playlist, playlist_id})
  end

  @impl true
  def get_devices(session_id) do
    GenStateMachine.call(via(session_id), :get_devices)
  end

  @impl true
  def get_recommendations_from_artists(session_id, artist_ids) do
    GenStateMachine.call(via(session_id), {:get_recommendations_from_artists, artist_ids})
  end

  @impl true
  def transfer_playback(session_id, device_id) do
    GenStateMachine.call(via(session_id), {:transfer_playback, device_id})
  end

  @doc false
  @impl true
  def init({session_id, credentials}) do
    data = %__MODULE__{session_id: session_id, credentials: credentials}
    action = {:next_event, :internal, :authenticate}
    {:ok, :not_authenticated, data, action}
  end

  @doc false
  @impl true
  def handle_event(event_type, :authenticate, :not_authenticated, data)
      when event_type in [:internal, :state_timeout] do
    case HttpApi.get_profile(data.credentials.token) do
      {:ok, user} ->
        data = %{data | user: user}

        actions = [
          {:next_event, :internal, :get_now_playing},
          {:state_timeout, @now_playing_refresh_interval, :get_now_playing}
        ]

        {:next_state, :authenticated, data, actions}

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

      {:ok, now_playing} ->
        if data.now_playing !== now_playing do
          Tune.Spotify.Session.broadcast(data.session_id, {:now_playing, now_playing})
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
        %{now_playing: %{status: :playing}} = data
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
        %{now_playing: %{status: :paused}} = data
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
        {:search, q, opts},
        :authenticated,
        data
      ) do
    case HttpApi.search(data.credentials.token, q, opts) do
      {:ok, results} ->
        action = {:reply, from, {:ok, results}}
        {:keep_state_and_data, action}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:top_tracks, opts},
        :authenticated,
        data
      ) do
    case HttpApi.top_tracks(data.credentials.token, opts) do
      {:ok, tracks} ->
        action = {:reply, from, {:ok, tracks}}
        {:keep_state_and_data, action}

      error ->
        handle_common_errors(error, data, from)
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

      error ->
        handle_common_errors(error, data, from)
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

      error ->
        handle_common_errors(error, data, from)
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

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:seek, position_ms},
        :authenticated,
        data
      ) do
    case HttpApi.seek(data.credentials.token, position_ms) do
      :ok ->
        actions = [
          {:next_event, :internal, :get_now_playing},
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_album, album_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_album(data.credentials.token, album_id) do
      {:ok, album} ->
        actions = [
          {:reply, from, {:ok, album}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_artist, artist_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_artist(data.credentials.token, artist_id) do
      {:ok, artist} ->
        actions = [
          {:reply, from, {:ok, artist}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_artist_albums, artist_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_artist_albums(data.credentials.token, artist_id) do
      {:ok, albums} ->
        actions = [
          {:reply, from, {:ok, albums}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_show, show_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_show(data.credentials.token, show_id) do
      {:ok, show} ->
        actions = [
          {:reply, from, {:ok, show}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_episodes, show_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_episodes(data.credentials.token, show_id) do
      {:ok, episodes} ->
        actions = [
          {:reply, from, {:ok, episodes}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_playlist, playlist_id},
        :authenticated,
        data
      ) do
    case HttpApi.get_playlist(data.credentials.token, playlist_id) do
      {:ok, playlist} ->
        actions = [
          {:reply, from, {:ok, playlist}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event({:call, from}, :get_devices, :authenticated, data) do
    case HttpApi.get_devices(data.credentials.token) do
      {:ok, devices} ->
        actions = [
          {:reply, from, {:ok, devices}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event(
        {:call, from},
        {:get_recommendations_from_artists, artist_ids},
        :authenticated,
        data
      ) do
    case HttpApi.get_recommendations_from_artists(data.credentials.token, artist_ids) do
      {:ok, tracks} ->
        actions = [
          {:reply, from, {:ok, tracks}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event({:call, from}, {:transfer_playback, device_id}, :authenticated, data) do
    case HttpApi.transfer_playback(data.credentials.token, device_id) do
      :ok ->
        actions = [
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  def handle_event({:call, from}, _request, _state, _data) do
    action = {:reply, from, {:error, :not_authenticated}}
    {:keep_state_and_data, action}
  end

  defp handle_common_errors(error, data, from) do
    case error do
      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      # abnormal http error
      other ->
        action = {:reply, from, other}
        {:keep_state_and_data, action}
    end
  end

  defp via(token) do
    {:via, Registry, {SessionRegistry, token}}
  end
end
