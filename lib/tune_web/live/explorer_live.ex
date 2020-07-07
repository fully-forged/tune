defmodule TuneWeb.ExplorerLive do
  use TuneWeb, :live_view

  alias TuneWeb.{PlayerView, TrackView}

  @impl true
  def mount(_params, session, socket) do
    with {:ok, session_id} <- Map.fetch(session, "spotify_id"),
         {:ok, credentials} <- Map.fetch(session, "spotify_credentials") do
      {:ok, load_user(session_id, credentials, socket)}
    else
      :error ->
        {:ok, assign(socket, tracks: [], q: nil, status: :not_authenticated)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    q = Map.get(params, "q")

    cond do
      q == nil ->
        {:noreply,
         socket
         |> assign(:q, nil)
         |> assign(:tracks, [])}

      String.length(q) >= 3 ->
        socket = assign(socket, :q, q)
        types = [:track]

        case spotify().search(socket.assigns.session_id, q, types) do
          {:ok, results} ->
            {:noreply, assign(socket, :tracks, results.tracks)}

          _error ->
            {:noreply, socket}
        end

      true ->
        {:noreply,
         socket
         |> assign(:q, nil)
         |> assign(:tracks, [])}
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
    spotify().toggle_play(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("search", %{"q" => ""}, socket) do
    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :index))}
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :index, %{q: q}))}
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp load_user(session_id, credentials, socket) do
    with :ok <- spotify().setup(session_id, credentials),
         %Tune.Spotify.Schema.User{} = user = spotify().get_profile(session_id),
         now_playing = spotify().now_playing(session_id) do
      if connected?(socket) do
        Tune.Spotify.Session.subscribe(session_id)
      end

      assign(socket,
        status: :authenticated,
        session_id: session_id,
        user: user,
        now_playing: now_playing,
        tracks: [],
        q: nil
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
end
