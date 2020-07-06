defmodule Tune.Spotify.HttpApi do
  alias Tune.{Album, Artist, Episode, Publisher, Show, Track, User}
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

  def pause(token) do
    case json_put(@base_url <> "/me/player/pause", %{}, auth_headers(token)) do
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
        Jason.decode(response.body)

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
          {:error, :expired_token}
        else
          {:error, :invalid_token}
        end

      {:ok, %{status: status}} ->
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
    item =
      case get_in(data, ["item", "type"]) do
        "track" ->
          data
          |> Map.get("item")
          |> parse_track()

        "episode" ->
          data
          |> Map.get("item")
          |> parse_episode()
      end

    if Map.get(data, "is_playing") do
      {:playing, item}
    else
      {:paused, item}
    end
  end

  defp parse_track(item) do
    %Track{
      name: Map.get(item, "name"),
      artist: %Artist{name: get_in(item, ["artists", Access.at(0), "name"])},
      album: %Album{
        name: get_in(item, ["album", "name"]),
        thumbnails:
          item
          |> get_in(["album", "images"])
          |> parse_thumbnails()
      }
    }
  end

  defp parse_episode(item) do
    %Episode{
      name: Map.get(item, "name"),
      description: Map.get(item, "description"),
      thumbnails:
        item
        |> Map.get("images")
        |> parse_thumbnails(),
      show: %Show{
        name: get_in(item, ["show", "name"]),
        description: get_in(item, ["show", "description"]),
        total_episodes: get_in(item, ["show", "total_episodes"])
      },
      publisher: %Publisher{
        name: get_in(item, ["show", "publisher"])
      }
    }
  end

  defp parse_thumbnails(images) do
    Enum.into(images, %{}, fn
      %{"height" => 640, "url" => url} -> {:large, url}
      %{"height" => 300, "url" => url} -> {:medium, url}
      %{"height" => 64, "url" => url} -> {:small, url}
    end)
  end
end
