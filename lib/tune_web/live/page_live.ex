defmodule TuneWeb.PageLive do
  use TuneWeb, :live_view

  alias TuneWeb.PlayerComponent

  @impl true
  def mount(_params, session, socket) do
    case Map.get(session, "spotify_token") do
      nil ->
        {:ok, assign(socket, status: :not_authenticated)}

      spotify_token ->
        {:ok, load_user(spotify_token, socket)}
    end
  end

  defp spotify, do: Application.get_env(:tune, :spotify)

  defp load_user(token, socket) do
    with :ok <- spotify().setup(token),
         user = spotify().get_profile(token) do
      assign(socket, status: :authenticated, user: user, spotify_token: token)
    else
      {:error, _reason} ->
        assign(socket, status: :not_authenticated)
    end
  end
end
