defmodule TuneWeb.PlayerComponent do
  use TuneWeb, :live_component

  @impl true
  def render(assigns) do
    case spotify().now_playing(assigns.spotify_token) do
      {:playing, track} ->
        ~L(
          <div class="card now-playing">
            <%= img_tag track.album.thumbnail, alt: track.name, class: "card-img-top" %>
            <div class="card-body">
              <h5 class="card-title"><%= track.name %></h5>
              <h6 class="card-subtitle mb-2 text-muted"><%= track.artist.name %></h6>
            </div>
          </div>
        )

      :not_playing ->
        ~L(<p>Not playing.</p>)

      {:error, _reason} ->
        ~L(<p>Error fetching playing information.</p>)
    end
  end

  defp spotify, do: Application.get_env(:tune, :spotify)
end
