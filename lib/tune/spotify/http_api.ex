defmodule Tune.Spotify.HttpApi do
  alias Tune.{Album, Artist, Track, User}

  @base_url "https://api.spotify.com/v1"

  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  def get_profile(token) do
    case json_get("/me", auth_headers(token)) do
      {:ok, %{status: 200} = response} ->
        user =
          response.body
          |> Jason.decode!()
          |> parse_profile()

        {:ok, user}

      {:ok, %{status: status}} ->
        {:error, status}

      error ->
        error
    end
  end

  def now_playing(token) do
    case json_get("/me/player", auth_headers(token)) do
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

  defp auth_headers(token) do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp json_get(path, headers) do
    get(path, @json_headers ++ headers)
  end

  defp get(path, headers) do
    Finch.build(:get, @base_url <> path, headers)
    |> Finch.request(Tune.Finch)
  end

  defp parse_profile(data) do
    name = Map.get(data, "display_name")
    avatar_url = get_in(data, ["images", Access.at(0), "url"])

    %User{name: name, avatar_url: avatar_url}
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
