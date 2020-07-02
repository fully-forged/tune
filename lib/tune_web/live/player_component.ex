defmodule TuneWeb.PlayerComponent do
  use TuneWeb, :live_component

  @impl true
  def render(assigns) do
    case spotify().now_playing(assigns.spotify_token) do
      {:playing, data} ->
        track = get_in(data, ["item", "name"])
        ~L(<p>Playing <%= track %>.</p>)

      :not_playing ->
        ~L(<p>Not playing.</p>)

      {:error, _reason} ->
        ~L(<p>Error fetching playing information.</p>)
    end
  end

  defp spotify, do: Application.get_env(:tune, :spotify)
end
