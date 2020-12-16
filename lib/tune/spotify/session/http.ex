defmodule Tune.Spotify.Session.HTTP do
  @moduledoc """
  This module implements a state machine mapped to a user session, wrapping
  interaction with the Spotify API.

  ## General structure

  The state machine implements the `Tune.Spotify.Session` behaviour for its public API
  and uses `GenStateMachine` to model its lifecycle.

  If you're not familiar with the `gen_statem` behaviour (which powers
  `GenStateMachine`), it's beneficial to read
  <http://erlang.org/doc/design_principles/statem.html> before proceeding
  further.

  The state machine uses the `handle_event_function` callback mode and has 3
  states: `:not_authenticated`, `:authenticated` and `:expired`.

  ```
                                ┌─────────────────┐
                                │Not authenticated│
                                └─────────────────┘
                                         │
                                         │
                                         ▼
                               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─
                      ┌────────    Authenticate   │─────────┐
                      │        └ ─ ─ ─ ─ ─ ─ ─ ─ ─          │
                      │                  │                  │
                  Success             Token             Invalid
                      │              expired             token
                      │                  │                  │
                      │                  │                  │
                      ▼                  ▼                  ▼
               ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
               │Authenticated│    │   Expired   │    │    Stop     │
               └─────────────┘    └─────────────┘    └─────────────┘
                      ▲                  │                  ▲
                      │              Get new                │
                  Success             token                 │
                      │    ┌ ─ ─ ─ ─     │                  │
                      └──── Refresh │◀───┘                  │
                           └ ─ ─ ─ ─                        │
                                │                           │
                                │          Invalid          │
                                └──────────refresh ─────────┘
                                            token
  ```

  When the process starts, it tries to authenticate against the Spotify API
  using the provided credentials. If successful, it enters the authenticated
  state, where all API functions can be executed correctly.

  If authentication fails because the authentication token has expired, the
  process tries to get a new token using the refresh token supplied by the
  Spotify API. This process effectively extends the duration of the session.

  Any error that indicates that credentials are invalid causes the process to
  stop. Any transient network error automatically triggers a delayed retry,
  which guarantees that _eventually_ the state machine reaches the
  authenticated state.

  ## Data lifecycle

  Aside from acting as an API client for on-demand operations (e.g. search,
  play/pause, etc.), the state machine also regularly polls the Spotify API for
  current player status and connected devices. Both pieces of information are
  kept in the state machine data for fast read and corresponding events are
  broadcasted when they change.

  Automatic data fetch is performed after successful authentication (via an
  `internal` event) and then scheduled via a `state_timeout` event. Once
  handled, the scheduled event requeues itself via the same `state_timeout` events.

  Usage of `state_timeout` events complies with the general state machine: if
  at any point the machine enters the expired state, any queued `state_timeout`
  event is automatically expired.

  Automatic fetching will resume once the machine enters the authenticated state.

  ## Subscriptions

  Multiple processes are able to subscribe to the events keyed by the session id.

  Broadcast and subscribe are implemented via `Phoenix.PubSub`, however the
  state machine maintains its own set of monitored processes subscribed to the session
  id.

  Subscription tracking is necessary to implementing automatic termination of a
  state machine after a period of inactivity. Without that, the state machine would
  indefinitely poll the Spotify API, even when no client is interested into the
  topic, until a crash error or a node reboot.

  Every 30 seconds, the state machine fires a named `timeout` event, checking if
  there's any subscribed process. If not, it terminates. Subscribed processes
  are monitored, so when they terminate, their exit is handled by the state machine,
  which removes them from its data.

  Usage of named `timeout` events is necessary, as they're guaranteed to fire
  irrespectively of state changes.
  """

  use GenStateMachine, restart: :transient
  @behaviour Tune.Spotify.Session

  alias Tune.Spotify.{Schema, Session, SessionRegistry}
  alias Phoenix.PubSub

  @default_timeouts %{
    refresh: 1000,
    retry: 5000,
    inactivity: 30_000
  }

  defstruct session_id: nil,
            credentials: nil,
            user: nil,
            now_playing: %Schema.Player{},
            devices: [],
            subscribers: MapSet.new(),
            timeouts: @default_timeouts

  @type timeouts :: %{
          refresh: timeout(),
          retry: timeout(),
          inactivity: timeout()
        }
  @type start_opts :: [
          {:timeouts, timeouts()}
        ]

  ################################################################################
  ################################## PUBLIC API ##################################
  ################################################################################

  @spec start_link({Session.id(), Session.credentials()}) ::
          {:ok, pid()} | {:error, term()}
  def start_link({session_id, credentials}),
    do: start_link(session_id, credentials, timeouts: @default_timeouts)

  @spec start_link({Session.id(), Session.credentials(), start_opts()}) ::
          {:ok, pid()} | {:error, term()}
  def start_link({session_id, credentials, start_opts}),
    do: start_link(session_id, credentials, start_opts)

  @spec start_link(Session.id(), Session.credentials(), start_opts()) ::
          {:ok, pid()} | {:error, term()}
  def start_link(session_id, credentials, start_opts) do
    GenStateMachine.start_link(__MODULE__, {session_id, credentials, start_opts},
      name: via(session_id)
    )
  end

  @impl true
  def setup(session_id, credentials) do
    Tune.Spotify.Supervisor.ensure_session(session_id, credentials)
  end

  @impl true
  def subscribe(session_id) do
    PubSub.subscribe(Tune.PubSub, session_id)
    caller = self()
    GenStateMachine.call(via(session_id), {:subscribe, caller})
  end

  @impl true
  def subscribers_count(session_id) do
    GenStateMachine.call(via(session_id), :subscribers_count)
  end

  @impl true
  def broadcast(session_id, message) do
    PubSub.broadcast(Tune.PubSub, session_id, message)
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
  def play(session_id, uri, context_uri) do
    GenStateMachine.call(via(session_id), {:play, uri, context_uri})
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
  def recently_played_tracks(session_id, opts) do
    GenStateMachine.call(via(session_id), {:recently_played_tracks, opts})
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
  def get_artist_albums(session_id, artist_id, opts) do
    GenStateMachine.call(via(session_id), {:get_artist_albums, artist_id, opts})
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
  def refresh_devices(session_id) do
    GenStateMachine.call(via(session_id), :refresh_devices)
  end

  @impl true
  def get_recommendations_from_artists(session_id, artist_ids) do
    GenStateMachine.call(via(session_id), {:get_recommendations_from_artists, artist_ids})
  end

  @impl true
  def transfer_playback(session_id, device_id) do
    GenStateMachine.call(via(session_id), {:transfer_playback, device_id})
  end

  @impl true
  def set_volume(session_id, volume_percent) do
    GenStateMachine.call(via(session_id), {:set_volume, volume_percent})
  end

  @impl true
  def get_player_token(session_id) do
    GenStateMachine.call(via(session_id), :get_player_token)
  end

  ################################################################################
  ################################## CALLBACKS ###################################
  ################################################################################

  @doc false
  @impl true
  def init({session_id, credentials, start_opts}) do
    timeouts = Keyword.get(start_opts, :timeouts, @default_timeouts)
    data = %__MODULE__{session_id: session_id, credentials: credentials, timeouts: timeouts}
    action = {:next_event, :internal, :authenticate}
    {:ok, :not_authenticated, data, action}
  end

  @doc false
  @impl true
  def handle_event(event_type, :authenticate, :not_authenticated, data)
      when event_type in [:internal, :state_timeout] do
    case spotify_client().get_profile(data.credentials.token) do
      {:ok, user} ->
        data = %{data | user: user}

        broadcast(data.session_id, {:player_token, data.credentials.token})

        actions = [
          {:next_event, :internal, :get_now_playing},
          {:next_event, :internal, :get_devices},
          {:state_timeout, data.timeouts.refresh, :refresh_data},
          {{:timeout, :inactivity}, data.timeouts.inactivity, :expired}
        ]

        {:next_state, :authenticated, data, actions}

      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, data.timeouts.retry, :authenticate}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(event_type, :refresh, :expired, data)
      when event_type in [:internal, :state_timeout] do
    case spotify_client().get_token(data.credentials.refresh_token) do
      {:ok, new_credentials} ->
        data = %{data | credentials: new_credentials}
        action = {:next_event, :internal, :authenticate}
        {:next_state, :not_authenticated, data, action}

      {:error, status} when is_integer(status) ->
        {:stop, :invalid_refresh_token}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, data.timeouts.retry, :refresh}
        {:keep_state_and_data, action}
    end
  end

  def handle_event(:internal, :get_now_playing, :authenticated, data) do
    case spotify_client().now_playing(data.credentials.token) do
      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, data.timeouts.retry, :get_now_playing}
        {:keep_state_and_data, action}

      {:ok, now_playing} ->
        if data.now_playing !== now_playing do
          broadcast(data.session_id, {:now_playing, now_playing})
        end

        data = %{data | now_playing: now_playing}

        {:keep_state, data}
    end
  end

  def handle_event(:internal, :get_devices, :authenticated, data) do
    case spotify_client().get_devices(data.credentials.token) do
      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, data.timeouts.retry, :get_devices}
        {:keep_state_and_data, action}

      {:ok, devices} ->
        if data.devices !== devices do
          broadcast(data.session_id, {:devices, devices})
        end

        data = %{data | devices: devices}

        {:keep_state, data}
    end
  end

  def handle_event(:state_timeout, :refresh_data, :authenticated, data) do
    with {:ok, now_playing} <- spotify_client().now_playing(data.credentials.token),
         {:ok, devices} <- spotify_client().get_devices(data.credentials.token) do
      if data.now_playing !== now_playing do
        broadcast(data.session_id, {:now_playing, now_playing})
      end

      if data.devices !== devices do
        broadcast(data.session_id, {:devices, devices})
      end

      data = %{data | now_playing: now_playing, devices: devices}

      action = {:state_timeout, data.timeouts.refresh, :refresh_data}

      {:keep_state, data, action}
    else
      {:error, :invalid_token} ->
        {:stop, :invalid_token}

      {:error, :expired_token} ->
        action = {:next_event, :internal, :refresh}
        {:next_state, :expired, data, action}

      # abnormal http error, retry in 5 seconds
      {:error, _reason} ->
        action = {:state_timeout, data.timeouts.retry, :refresh_data}
        {:keep_state_and_data, action}
    end
  end

  def handle_event({:call, from}, {:subscribe, pid}, _state, data) do
    new_subscribers = MapSet.put(data.subscribers, pid)
    Process.monitor(pid)
    action = {:reply, from, :ok}
    {:keep_state, %{data | subscribers: new_subscribers}, action}
  end

  def handle_event({:call, from}, :subscribers_count, _state, data) do
    action = {:reply, from, MapSet.size(data.subscribers)}
    {:keep_state_and_data, action}
  end

  def handle_event({:call, from}, msg, :authenticated, data) do
    handle_authenticated_call(from, msg, data)
  end

  def handle_event({:call, from}, _request, _state, _data) do
    action = {:reply, from, {:error, :not_authenticated}}
    {:keep_state_and_data, action}
  end

  def handle_event({:timeout, :inactivity}, :expired, _state, data) do
    if MapSet.size(data.subscribers) == 0 do
      {:stop, :normal}
    else
      action = {{:timeout, :inactivity}, data.timeouts.inactivity, :expired}
      {:keep_state_and_data, action}
    end
  end

  def handle_event(:info, {:DOWN, _ref, :process, pid, _reason}, _state, data) do
    new_subscribers = MapSet.delete(data.subscribers, pid)

    {:keep_state, %{data | subscribers: new_subscribers}}
  end

  ################################################################################
  ########################### INTERNAL IMPLEMENTATION ############################
  ################################################################################

  defp handle_authenticated_call(from, :get_profile, data) do
    action = {:reply, from, data.user}
    {:keep_state_and_data, action}
  end

  defp handle_authenticated_call(from, :now_playing, data) do
    action = {:reply, from, data.now_playing}
    {:keep_state_and_data, action}
  end

  defp handle_authenticated_call(from, :toggle_play, %{now_playing: %{status: :playing}} = data) do
    case spotify_client().pause(data.credentials.token) do
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

  defp handle_authenticated_call(from, :toggle_play, %{now_playing: %{status: :paused}} = data) do
    case spotify_client().play(data.credentials.token) do
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

  defp handle_authenticated_call(from, :toggle_play, _data) do
    action = {:reply, from, :ok}
    {:keep_state_and_data, action}
  end

  defp handle_authenticated_call(from, {:search, q, opts}, data) do
    case spotify_client().search(data.credentials.token, q, opts) do
      {:ok, results} ->
        action = {:reply, from, {:ok, results}}
        {:keep_state_and_data, action}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:recently_played_tracks, opts}, data) do
    case spotify_client().recently_played_tracks(data.credentials.token, opts) do
      {:ok, tracks} ->
        action = {:reply, from, {:ok, tracks}}
        {:keep_state_and_data, action}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:top_tracks, opts}, data) do
    case spotify_client().top_tracks(data.credentials.token, opts) do
      {:ok, tracks} ->
        action = {:reply, from, {:ok, tracks}}
        {:keep_state_and_data, action}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:play, uri}, data) do
    case spotify_client().play(data.credentials.token, uri) do
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

  defp handle_authenticated_call(from, {:play, uri, context_uri}, data) do
    case spotify_client().play(data.credentials.token, uri, context_uri) do
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

  defp handle_authenticated_call(from, :next, data) do
    case spotify_client().next(data.credentials.token) do
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

  defp handle_authenticated_call(from, :prev, data) do
    case spotify_client().prev(data.credentials.token) do
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

  defp handle_authenticated_call(from, {:seek, position_ms}, data) do
    case spotify_client().seek(data.credentials.token, position_ms) do
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

  defp handle_authenticated_call(from, {:get_album, album_id}, data) do
    case spotify_client().get_album(data.credentials.token, album_id) do
      {:ok, album} ->
        actions = [
          {:reply, from, {:ok, album}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:get_artist, artist_id}, data) do
    case spotify_client().get_artist(data.credentials.token, artist_id) do
      {:ok, artist} ->
        actions = [
          {:reply, from, {:ok, artist}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:get_artist_albums, artist_id, opts}, data) do
    case spotify_client().get_artist_albums(data.credentials.token, artist_id, opts) do
      {:ok, albums} ->
        actions = [
          {:reply, from, {:ok, albums}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:get_show, show_id}, data) do
    case spotify_client().get_show(data.credentials.token, show_id) do
      {:ok, show} ->
        actions = [
          {:reply, from, {:ok, show}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:get_episodes, show_id}, data) do
    case spotify_client().get_episodes(data.credentials.token, show_id) do
      {:ok, episodes} ->
        actions = [
          {:reply, from, {:ok, episodes}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:get_playlist, playlist_id}, data) do
    case spotify_client().get_playlist(data.credentials.token, playlist_id) do
      {:ok, playlist} ->
        actions = [
          {:reply, from, {:ok, playlist}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, :get_devices, data) do
    action = {:reply, from, data.devices}
    {:keep_state_and_data, action}
  end

  defp handle_authenticated_call(from, :refresh_devices, _data) do
    actions = [{:next_event, :internal, :get_devices}, {:reply, from, :ok}]
    {:keep_state_and_data, actions}
  end

  defp handle_authenticated_call(from, {:get_recommendations_from_artists, artist_ids}, data) do
    case spotify_client().get_recommendations_from_artists(data.credentials.token, artist_ids) do
      {:ok, tracks} ->
        actions = [
          {:reply, from, {:ok, tracks}}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, :get_player_token, data) do
    actions = [
      {:reply, from, {:ok, data.credentials.token}}
    ]

    {:keep_state_and_data, actions}
  end

  defp handle_authenticated_call(from, {:transfer_playback, device_id}, data) do
    case spotify_client().transfer_playback(data.credentials.token, device_id) do
      :ok ->
        actions = [
          {:reply, from, :ok}
        ]

        {:keep_state_and_data, actions}

      error ->
        handle_common_errors(error, data, from)
    end
  end

  defp handle_authenticated_call(from, {:set_volume, volume_percent}, data) do
    case spotify_client().set_volume(data.credentials.token, volume_percent) do
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

  defp via(session_id) do
    {:via, Registry, {SessionRegistry, session_id}}
  end

  defp spotify_client, do: Application.get_env(:tune, :spotify_client)
end
