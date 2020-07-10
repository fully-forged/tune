defmodule TuneWeb.ExplorerLive do
  use TuneWeb, :live_view

  alias TuneWeb.{AlbumView, PlayerView, SearchView}

  @initial_state [
    status: :not_authenticated,
    q: nil,
    type: :track,
    results: [],
    user: nil,
    now_playing: :not_playing,
    item: nil,
    results_per_page: 32
  ]

  @impl true
  def mount(_params, session, socket) do
    with {:ok, session_id} <- Map.fetch(session, "spotify_id"),
         {:ok, credentials} <- Map.fetch(session, "spotify_credentials") do
      {:ok, load_user(session_id, credentials, socket)}
    else
      :error ->
        {:ok, assign(socket, @initial_state)}
    end
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{status: :not_authenticated}} = socket) do
    {:noreply, socket}
  end

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
          {:noreply, assign(socket, :results, extract_results(results, type))}

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
    case spotify().get_artist(socket.assigns.session_id, artist_id) do
      {:ok, artist} ->
        {:noreply, assign(socket, :item, artist)}

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
    spotify().toggle_play(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("play", %{"uri" => uri}, socket) do
    spotify().play(socket.assigns.session_id, uri)

    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    spotify().next(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("prev", _params, socket) do
    spotify().prev(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("search", params, socket) do
    q = Map.get(params, "q")
    type = Map.get(params, "type", "track")

    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :index, q: q, type: type))}
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp load_user(session_id, credentials, socket) do
    with :ok <- spotify().setup(session_id, credentials),
         %Tune.Spotify.Schema.User{} = user = spotify().get_profile(session_id),
         now_playing = spotify().now_playing(session_id) do
      if connected?(socket) do
        Tune.Spotify.Session.subscribe(session_id)
      end

      socket
      |> assign(@initial_state)
      |> assign(
        status: :authenticated,
        session_id: session_id,
        user: user,
        now_playing: now_playing
      )
    else
      {:error, _reason} ->
        redirect(socket, to: "/auth/logout")
    end
  end

  @impl true
  def handle_info(now_playing, socket) do
    {:noreply, assign(socket, :now_playing, now_playing)}
  end

  defp parse_type("track"), do: :track
  defp parse_type("album"), do: :album
  defp parse_type("artist"), do: :artist
  defp parse_type("episode"), do: :episode
  defp parse_type("show"), do: :show

  defp extract_results(results, :track), do: Map.get(results, :tracks)
  defp extract_results(results, :album), do: Map.get(results, :albums)
  defp extract_results(results, :artist), do: Map.get(results, :artists)
  defp extract_results(results, :episode), do: Map.get(results, :episodes)
  defp extract_results(results, :show), do: Map.get(results, :shows)
end
