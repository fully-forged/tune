defmodule Tune.Spotify.Client do
  @behaviour Tune.Spotify

  alias Tune.{Album, Artist, Track}

  @base_url "https://api.spotify.com/v1"

  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  def get_profile(token) do
    headers = @json_headers ++ authorization_headers(token)

    case get("/me", headers) do
      {:ok, %{status: 200} = response} ->
        Jason.decode(response.body)

      {:ok, %{status: status}} ->
        {:error, status}

      error ->
        error
    end
  end

  def now_playing(token) do
    headers = @json_headers ++ authorization_headers(token)

    case get("/me/player", headers) do
      {:ok, %{status: 204}} ->
        :not_playing

      {:ok, %{status: 200} = response} ->
        track =
          response.body
          |> Jason.decode!()
          |> parse_now_playing()

        {:playing, track}

      {:ok, %{status: status}} ->
        {:error, status}

      error ->
        error
    end
  end

  defp authorization_headers(token) do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp get(path, headers) do
    Finch.build(:get, @base_url <> path, headers)
    |> Finch.request(Tune.Finch)
  end

  defp parse_now_playing(data) do
    track_name = get_in(data, ["item", "name"])
    track_artist = get_in(data, ["item", "artists", Access.at(0), "name"])
    album_name = get_in(data, ["item", "album", "name"])
    album_thumbnail = get_in(data, ["item", "album", "images", Access.at(0), "url"])

    %Track{
      name: track_name,
      artist: %Artist{name: track_artist},
      album: %Album{name: album_name, thumbnail: album_thumbnail}
    }
  end
end
