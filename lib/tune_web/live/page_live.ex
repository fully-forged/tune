defmodule TuneWeb.PageLive do
  use TuneWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    spotify_token = Map.get(session, "spotify_token")

    {:ok, user} = spotify().get_profile(spotify_token)
    now_playing = spotify().now_playing(spotify_token)

    {:ok, assign(socket, user: user, current_track: current_track(now_playing))}
  end

  defp current_track(:not_playing), do: "Nothing playing"

  defp current_track({:playing, data}) do
    get_in(data, ["item", "name"])
  end

  defp current_track({:error, _reason}), do: "Error getting now playing"

  defp spotify, do: Application.get_env(:tune, :spotify)
end
