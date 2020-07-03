defmodule TuneWeb.PageLive do
  use TuneWeb, :live_view

  alias TuneWeb.PlayerView

  @impl true
  def mount(_params, session, socket) do
    with {:ok, session_id} <- Map.fetch(session, "spotify_id"),
         {:ok, credentials} <- Map.fetch(session, "spotify_credentials") do
      {:ok, load_user(session_id, credentials, socket)}
    else
      :error ->
        {:ok, assign(socket, status: :not_authenticated)}
    end
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp load_user(session_id, credentials, socket) do
    with :ok <- spotify().setup(session_id, credentials),
         user = spotify().get_profile(session_id),
         now_playing = spotify().now_playing(session_id) do
      if connected?(socket) do
        spotify().subscribe(session_id)
      end

      assign(socket,
        status: :authenticated,
        user: user,
        now_playing: now_playing
      )
    else
      {:error, _reason} ->
        assign(socket, status: :not_authenticated)
    end
  end

  @impl true
  def handle_info(now_playing, socket) do
    {:noreply, assign(socket, :now_playing, now_playing)}
  end
end
