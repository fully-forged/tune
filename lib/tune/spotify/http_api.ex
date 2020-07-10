defmodule Tune.Spotify.HttpApi do
  alias Tune.Spotify.Schema.{Album, Artist, Episode, Publisher, Show, Track, User}
  alias Tune.Spotify.Auth

  require Logger

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

      other_response ->
        handle_errors(other_response)
    end
  end

  def now_playing(token) do
    case json_get(@base_url <> "/me/player?additional_types=episode", auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :not_playing

      {:ok, %{status: 200} = response} ->
        response.body
        |> Jason.decode!()
        |> parse_now_playing()

      other_response ->
        handle_errors(other_response)
    end
  end

  def play(token) do
    case json_put(@base_url <> "/me/player/play", %{}, auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :ok

      other_response ->
        handle_errors(other_response)
    end
  end

  def play(token, uri) do
    payload =
      if uri =~ "track" do
        %{uris: [uri]}
      else
        %{context_uri: uri}
      end

    case json_put(@base_url <> "/me/player/play", payload, auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :ok

      other_response ->
        handle_errors(other_response)
    end
  end

  def pause(token) do
    case json_put(@base_url <> "/me/player/pause", %{}, auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :ok

      other_response ->
        handle_errors(other_response)
    end
  end

  def next(token) do
    case post(@base_url <> "/me/player/next", <<>>, auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :ok

      other_response ->
        handle_errors(other_response)
    end
  end

  def prev(token) do
    case post(@base_url <> "/me/player/previous", <<>>, auth_headers(token)) do
      {:ok, %{status: 204}} ->
        :ok

      other_response ->
        handle_errors(other_response)
    end
  end

  def get_token(refresh_token) do
    headers = [
      {"Authorization", "Basic #{Auth.base64_encoded_credentials()}"}
    ]

    case form_post(
           @refresh_url,
           %{grant_type: "refresh_token", refresh_token: refresh_token},
           headers
         ) do
      {:ok, %{status: 200} = response} ->
        auth_data =
          response.body
          |> Jason.decode!()
          |> parse_auth_data(refresh_token)

        {:ok, auth_data}

      other_response ->
        handle_errors(other_response)
    end
  end

  def search(token, q, types) do
    types_string = Enum.join(types, ",")

    params = %{
      q: q,
      type: types_string,
      market: "from_token"
    }

    case json_get(@base_url <> "/search?" <> URI.encode_query(params), auth_headers(token)) do
      {:ok, %{status: 200} = response} ->
        results =
          response.body
          |> Jason.decode!()
          |> parse_search_results(types)

        {:ok, results}

      other_response ->
        handle_errors(other_response)
    end
  end

  defp auth_headers(token) do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp json_get(url, headers) do
    get(url, @json_headers ++ headers)
  end

  defp json_put(url, params, headers) do
    put(url, Jason.encode!(params), @json_headers ++ headers)
  end

  defp form_post(url, params, headers) do
    post(url, URI.encode_query(params), @form_headers ++ headers)
  end

  defp get(url, headers) do
    Finch.build(:get, url, headers)
    |> Finch.request(Tune.Finch)
  end

  defp post(url, body, headers) do
    Finch.build(:post, url, headers, body)
    |> Finch.request(Tune.Finch)
  end

  defp put(url, body, headers) do
    Finch.build(:put, url, headers, body)
    |> Finch.request(Tune.Finch)
  end

  defp parse_profile(data) do
    name = Map.get(data, "display_name")
    avatar_url = get_in(data, ["images", Access.at(0), "url"])

    %User{name: name, avatar_url: avatar_url}
  end

  defp handle_errors(response) do
    case response do
      {:ok, %{status: 401, body: body}} ->
        if body =~ "expired" do
          Logger.warn(fn ->
            "Spotify HTTP Api error: expired token"
          end)

          {:error, :expired_token}
        else
          Logger.warn(fn ->
            "Spotify HTTP Api error: invalid token"
          end)

          {:error, :invalid_token}
        end

      {:ok, %{status: status}} ->
        Logger.warn(fn ->
          "Spotify HTTP Api error: #{status}"
        end)

        {:error, status}

      error ->
        error
    end
  end

  defp parse_auth_data(data, refresh_token) do
    %Ueberauth.Auth.Credentials{
      expires: true,
      expires_at: OAuth2.Util.unix_now() + data["expires_in"],
      refresh_token: refresh_token,
      scopes: [data["scope"]],
      token: data["access_token"],
      token_type: data["token_type"]
    }
  end

  defp parse_now_playing(data) do
    case get_in(data, ["item", "type"]) do
      "track" ->
        item =
          data
          |> Map.get("item")
          |> parse_track()

        if Map.get(data, "is_playing") do
          {:playing, item}
        else
          {:paused, item}
        end

      "episode" ->
        item =
          data
          |> Map.get("item")
          |> parse_episode_with_metadata()

        if Map.get(data, "is_playing") do
          {:playing, item}
        else
          {:paused, item}
        end

      nil ->
        :not_playing
    end
  end

  defp parse_track(item) do
    %Track{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      artist:
        item
        |> get_in(["artists", Access.at(0)])
        |> parse_artist(),
      album:
        item
        |> Map.get("album")
        |> parse_album()
    }
  end

  defp parse_artist(item) do
    %Artist{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      thumbnails:
        if Map.has_key?(item, "images") do
          item
          |> Map.get("images")
          |> parse_thumbnails()
        else
          :not_fetched
        end
    }
  end

  defp parse_album(item) do
    %Album{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      artist:
        item
        |> get_in(["artists", Access.at(0)])
        |> parse_artist(),
      thumbnails:
        item
        |> Map.get("images")
        |> parse_thumbnails()
    }
  end

  defp parse_episode_with_metadata(item) do
    %Episode{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      description: Map.get(item, "description"),
      thumbnails:
        item
        |> Map.get("images")
        |> parse_thumbnails(),
      show:
        item
        |> Map.get("show")
        |> parse_show(),
      publisher: %Publisher{
        name: get_in(item, ["show", "publisher"])
      }
    }
  end

  defp parse_episode(item) do
    %Episode{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      description: Map.get(item, "description"),
      thumbnails:
        item
        |> Map.get("images")
        |> parse_thumbnails(),
      show: :not_fetched,
      publisher: :not_fetched
    }
  end

  defp parse_show(item) do
    %Show{
      id: Map.get(item, "id"),
      uri: Map.get(item, "uri"),
      name: Map.get(item, "name"),
      description: Map.get(item, "description"),
      publisher: %Publisher{
        name: Map.get(item, "publisher")
      },
      thumbnails:
        item
        |> Map.get("images")
        |> parse_thumbnails(),
      total_episodes: Map.get(item, "total_episodes")
    }
  end

  defp parse_thumbnails(images) do
    Enum.into(images, %{}, fn
      %{"height" => height, "url" => url} when height in 0..199 -> {:small, url}
      %{"height" => height, "url" => url} when height in 200..449 -> {:medium, url}
      %{"height" => height, "url" => url} when height >= 450 -> {:large, url}
    end)
  end

  defp parse_search_results(results, types) do
    Enum.reduce(types, %{}, fn
      :album, acc ->
        albums =
          results
          |> get_in(["albums", "items"])
          |> Enum.map(&parse_album/1)

        Map.put(acc, :albums, albums)

      :artist, acc ->
        artists =
          results
          |> get_in(["artists", "items"])
          |> Enum.map(&parse_artist/1)

        Map.put(acc, :artists, artists)

      :track, acc ->
        tracks =
          results
          |> get_in(["tracks", "items"])
          |> Enum.map(&parse_track/1)

        Map.put(acc, :tracks, tracks)

      :show, acc ->
        shows =
          results
          |> get_in(["shows", "items"])
          |> Enum.map(&parse_show/1)

        Map.put(acc, :shows, shows)

      :episode, acc ->
        episodes =
          results
          |> get_in(["episodes", "items"])
          |> Enum.map(&parse_episode/1)

        Map.put(acc, :episodes, episodes)
    end)
  end
end
