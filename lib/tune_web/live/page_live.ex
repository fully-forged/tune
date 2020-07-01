defmodule TuneWeb.PageLive do
  use TuneWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok, user} =
      session
      |> Map.get("spotify_token")
      |> spotify().get_profile()

    {:ok, assign(socket, user: user)}
  end

  defp spotify, do: Application.get_env(:tune, :spotify)
end
