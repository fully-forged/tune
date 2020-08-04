defmodule TuneWeb.ExplorerLive do
  @moduledoc """
  Main view used in the application. Covers:

  - search
  - displaying details for artists, albums, etc.
  - mini player
  """

  use TuneWeb, :live_view

  alias Tune.Spotify.Schema.{Album, Player}

  alias TuneWeb.{
    AlbumView,
    ArtistView,
    MiniPlayerComponent,
    ProgressBarComponent,
    SearchView,
    SuggestionsView
  }

  @default_time_range "short_term"

  @initial_state [
    q: nil,
    type: :track,
    results: [],
    user: nil,
    now_playing: %Tune.Spotify.Schema.Player{},
    item: nil,
    results_per_page: 32,
    suggestions_playlist: :not_fetched,
    suggestions_top_albums: :not_fetched,
    suggestions_top_albums_time_range: @default_time_range,
    suggestions_recommended_tracks: :not_fetched,
    suggestions_recommended_tracks_time_range: @default_time_range
  ]

  @impl true
  def mount(_params, session, socket) do
    case Tune.Auth.load_user(session) do
      {:authenticated, session_id, user} ->
        now_playing = spotify().now_playing(session_id)

        socket =
          case spotify().get_devices(session_id) do
            {:ok, devices} ->
              assign(socket, :devices, devices)

            _error ->
              socket
          end

        if connected?(socket) do
          Tune.Spotify.Session.subscribe(session_id)
        end

        {:ok,
         socket
         |> assign(@initial_state)
         |> assign(
           session_id: session_id,
           user: user,
           now_playing: now_playing
         )}

      _error ->
        {:ok, redirect(socket, to: "/auth/logout")}
    end
  end

  @impl true
  def handle_params(params, url, socket) do
    case socket.assigns.live_action do
      :suggestions -> handle_suggestions(params, url, socket)
      :search -> handle_search(params, url, socket)
      :artist_details -> handle_artist_details(params, url, socket)
      :album_details -> handle_album_details(params, url, socket)
      :show_details -> handle_show_details(params, url, socket)
      :episode_details -> handle_episode_details(params, url, socket)
    end
  end

  @impl true
  def handle_event("toggle_play_pause", %{"key" => " "}, socket) do
    spotify().toggle_play(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("toggle_play_pause", %{"key" => _}, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_play_pause", _params, socket) do
    socket.assigns.session_id
    |> spotify().toggle_play()
    |> handle_device_operation_result(socket)
  end

  def handle_event("play", %{"uri" => uri}, socket) do
    socket.assigns.session_id
    |> spotify().play(uri)
    |> handle_device_operation_result(socket)
  end

  def handle_event("next", _params, socket) do
    socket.assigns.session_id
    |> spotify().next()
    |> handle_device_operation_result(socket)
  end

  def handle_event("prev", _params, socket) do
    socket.assigns.session_id
    |> spotify().prev()
    |> handle_device_operation_result(socket)
  end

  def handle_event("seek", %{"position_ms" => position_ms}, socket) do
    socket.assigns.session_id
    |> spotify().seek(position_ms)
    |> handle_device_operation_result(socket)
  end

  def handle_event("search", params, socket) do
    q = Map.get(params, "q")
    type = Map.get(params, "type", "track")

    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :search, q: q, type: type))}
  end

  def handle_event("set_top_albums_time_range", %{"time-range" => time_range}, socket) do
    case get_top_tracks(socket.assigns.session_id, time_range) do
      {:ok, top_tracks} ->
        {:noreply,
         assign(socket,
           suggestions_top_albums: Album.from_tracks(top_tracks),
           suggestions_top_albums_time_range: time_range
         )}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("set_recommended_tracks_time_range", %{"time-range" => time_range}, socket) do
    with {:ok, top_tracks} <- get_top_tracks(socket.assigns.session_id, time_range),
         {:ok, recommended_tracks} <- get_recommendations(socket.assigns.session_id, top_tracks) do
      {:noreply,
       assign(socket,
         suggestions_recommended_tracks: recommended_tracks,
         suggestions_recommended_tracks_time_range: time_range
       )}
    else
      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("transfer_playback", %{"device" => device_id}, socket) do
    with :ok <- spotify().transfer_playback(socket.assigns.session_id, device_id),
         {:ok, devices} <- spotify().get_devices(socket.assigns.session_id) do
      {:noreply, assign(socket, :devices, devices)}
    else
      _error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:now_playing, player}, socket) do
    case Player.changes(socket.assigns.now_playing, player) do
      :progress_changed ->
        send_update(ProgressBarComponent, id: :progress_bar, progress_ms: player.progress_ms)
        {:noreply, socket}

      _status_or_item_changed ->
        {:noreply, assign(socket, :now_playing, player)}
    end
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp handle_suggestions(_params, _url, socket) do
    with {:ok, playlist} <- get_suggestions_playlist(socket.assigns.session_id),
         {:ok, top_tracks} <-
           get_top_tracks(
             socket.assigns.session_id,
             socket.assigns.suggestions_top_albums_time_range
           ),
         {:ok, recommended_tracks} <-
           get_recommendations(socket.assigns.session_id, top_tracks) do
      {:noreply,
       assign(socket,
         suggestions_playlist: playlist,
         suggestions_top_albums: Album.from_tracks(top_tracks),
         suggestions_recommended_tracks: recommended_tracks
       )}
    else
      {:error, :not_present} ->
        {:noreply, assign(socket, :suggestions_playlist, :not_present)}

      error ->
        error |> IO.inspect()
        {:noreply, socket}
    end
  end

  defp handle_search(params, _url, socket) do
    q = Map.get(params, "q", "")
    type = Map.get(params, "type", "track")

    if String.length(q) >= 1 do
      type = parse_type(type)

      socket =
        socket
        |> assign(:q, q)
        |> assign(:type, type)

      search_opts = [types: [type], limit: socket.assigns.results_per_page]

      case spotify().search(socket.assigns.session_id, q, search_opts) do
        {:ok, results} ->
          {:noreply, assign(socket, :results, Map.get(results, type))}

        _error ->
          {:noreply, socket}
      end
    else
      {:noreply,
       socket
       |> assign(:q, nil)
       |> assign(:type, type)
       |> assign(:results, [])}
    end
  end

  defp handle_artist_details(%{"artist_id" => artist_id}, _url, socket) do
    with {:ok, artist} <- spotify().get_artist(socket.assigns.session_id, artist_id),
         {:ok, albums} <- spotify().get_artist_albums(socket.assigns.session_id, artist_id) do
      artist = %{artist | albums: albums}

      {:noreply, assign(socket, :item, artist)}
    else
      _error ->
        {:noreply, socket}
    end
  end

  defp handle_album_details(%{"album_id" => album_id}, _url, socket) do
    case spotify().get_album(socket.assigns.session_id, album_id) do
      {:ok, album} ->
        {:noreply, assign(socket, :item, album)}

      _error ->
        {:noreply, socket}
    end
  end

  defp handle_show_details(%{"show_id" => show_id}, _url, socket) do
    case spotify().get_show(socket.assigns.session_id, show_id) do
      {:ok, show} ->
        {:noreply, assign(socket, :item, show)}

      _error ->
        {:noreply, socket}
    end
  end

  defp handle_episode_details(_params, _url, socket) do
    {:noreply, socket}
  end

  defp parse_type("track"), do: :track
  defp parse_type("album"), do: :album
  defp parse_type("artist"), do: :artist
  defp parse_type("episode"), do: :episode
  defp parse_type("show"), do: :show

  defp handle_device_operation_result(:ok, socket), do: {:noreply, socket}

  defp handle_device_operation_result({:error, 404}, socket) do
    {:noreply, put_flash(socket, :error, gettext("No available devices"))}
  end

  defp handle_device_operation_result({:error, reason}, socket) do
    error_message = gettext("Spotify error: %{reason}", %{reason: inspect(reason)})
    {:noreply, put_flash(socket, :error, error_message)}
  end

  @suggestions_playlist_name "Release Radar"
  defp get_suggestions_playlist(session_id) do
    with {:ok, results} <-
           spotify().search(session_id, @suggestions_playlist_name,
             types: [:playlist],
             limit: 1
           ),
         [simplified_playlist] <- Map.get(results, :playlist) do
      spotify().get_playlist(session_id, simplified_playlist.id)
    else
      [] -> {:error, :not_present}
      error -> error
    end
  end

  @top_tracks_limit 32

  defp get_top_tracks(session_id, time_range) do
    opts = [limit: @top_tracks_limit, time_range: time_range]
    spotify().top_tracks(session_id, opts)
  end

  defp get_recommendations(session_id, tracks) do
    artist_ids =
      tracks
      |> Enum.map(& &1.artist.id)
      |> Enum.shuffle()
      |> Enum.take(5)

    spotify().get_recommendations_from_artists(session_id, artist_ids)
  end
end
