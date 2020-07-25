defmodule TuneWeb.ExplorerLive do
  @moduledoc """
  Main view used in the application. Covers:

  - search
  - displaying details for artists, albums, etc.
  - mini player
  """

  use TuneWeb, :live_view

  alias TuneWeb.{AlbumView, ArtistView, PlayerView, SearchView}

  @initial_state [
    q: nil,
    type: :track,
    results: [],
    user: nil,
    now_playing: %Tune.Spotify.Schema.Player{},
    item: nil,
    results_per_page: 32
  ]

  @impl true
  def mount(_params, session, socket) do
    case Tune.Auth.load_user(session) do
      {:authenticated, session_id, user} ->
        now_playing = spotify().now_playing(session_id)

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
  def handle_params(%{"q" => q} = params, _url, socket) do
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

  def handle_params(%{"artist_id" => artist_id}, _url, socket) do
    with {:ok, artist} <- spotify().get_artist(socket.assigns.session_id, artist_id),
         {:ok, albums} <- spotify().get_artist_albums(socket.assigns.session_id, artist_id) do
      artist = %{artist | albums: albums}

      {:noreply, assign(socket, :item, artist)}
    else
      _error ->
        {:noreply, socket}
    end
  end

  def handle_params(%{"album_id" => album_id}, _url, socket) do
    case spotify().get_album(socket.assigns.session_id, album_id) do
      {:ok, album} ->
        {:noreply, assign(socket, :item, album)}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_params(%{"show_id" => show_id}, _url, socket) do
    case spotify().get_show(socket.assigns.session_id, show_id) do
      {:ok, show} ->
        {:noreply, assign(socket, :item, show)}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:q, nil)
     |> assign(:results, [])}
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

  def handle_event("search", params, socket) do
    q = Map.get(params, "q")
    type = Map.get(params, "type", "track")

    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :search, q: q, type: type))}
  end

  @impl true
  def handle_info(now_playing, socket) do
    {:noreply, assign(socket, :now_playing, now_playing)}
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp parse_type("track"), do: :track
  defp parse_type("album"), do: :album
  defp parse_type("artist"), do: :artist
  defp parse_type("episode"), do: :episode
  defp parse_type("show"), do: :show

  defp handle_device_operation_result(:ok, socket), do: {:noreply, socket}

  defp handle_device_operation_result({:error, 404}, socket) do
    {:noreply, put_flash(socket, :error, "No available devices")}
  end

  defp handle_device_operation_result({:error, reason}, socket) do
    {:noreply, put_flash(socket, :error, "Spotify error: #{inspect(reason)}")}
  end
end
