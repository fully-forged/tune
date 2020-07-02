defmodule Tune.Spotify.HttpApi do
  alias Tune.{Album, Artist, Track, User}
  alias Tune.Spotify.Auth

  @base_url "https://api.spotify.com/v1"
  @refresh_url "https://accounts.spotify.com/api/token"

  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]
  @form_headers [
    {"Content-Type", "application/x-www-form-urlencoded"}
  ]

  def get_profile(token) do
    case json_get(@base_url <> "/me", auth_headers(token)) do
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
    case json_get(@base_url <> "/me/player", auth_headers(token)) do
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

  def get_token(refresh_token) do
    headers = [
      {"Authorization", "Basic #{Auth.base64_encoded_credentials()}"}
    ]

    case post(@refresh_url, %{grant_type: "refresh_token", refresh_token: refresh_token}, headers) do
      {:ok, response} ->
        response.body
        |> Jason.decode()

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

  defp get(url, headers) do
    Finch.build(:get, url, headers)
    |> Finch.request(Tune.Finch)
  end

  defp post(url, params, headers) when is_map(params) do
    Finch.build(:post, url, @form_headers ++ headers, URI.encode_query(params))
    |> Finch.request(Tune.Finch)
  end

  defp parse_profile(data) do
    name = Map.get(data, "display_name")
    avatar_url = get_in(data, ["images", Access.at(0), "url"])

    %User{name: name, avatar_url: avatar_url}
  end

  defp parse_now_playing(data) do
    playing = Map.get(data, "is_playing")
    track_name = get_in(data, ["item", "name"])
    track_artist = get_in(data, ["item", "artists", Access.at(0), "name"])
    album_name = get_in(data, ["item", "album", "name"])
    album_thumbnail = get_in(data, ["item", "album", "images", Access.at(0), "url"])

    %Track{
      name: track_name,
      playing: playing,
      artist: %Artist{name: track_artist},
      album: %Album{name: album_name, thumbnail: album_thumbnail}
    }
  end
end
