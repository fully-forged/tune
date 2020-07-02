defmodule TuneWeb.PlayerComponent do
  use TuneWeb, :live_component

  @impl true
  def render(assigns) do
    case spotify().now_playing(assigns.spotify_token) do
      {:playing, data} ->
        track_name = get_in(data, ["item", "name"])
        track_artist = get_in(data, ["item", "artists", Access.at(0), "name"])
        thumbnail = get_in(data, ["item", "album", "images", Access.at(0), "url"])

        ~L(
          <div class="card now-playing">
            <%= img_tag thumbnail, alt: track_name, class: "card-img-top" %>
            <div class="card-body">
              <h5 class="card-title"><%= track_name %></h5>
              <h6 class="card-subtitle mb-2 text-muted"><%= track_artist %></h6>
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
