defmodule Tune.Spotify.Client do
  @behaviour Tune.Spotify

  @base_url "https://api.spotify.com/v1"

  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  def get_profile(token) do
    headers = @json_headers ++ authorization_headers(token)

    case get("/me", headers) do
      {:ok, response} ->
        Jason.decode(response.body)

      error ->
        error
    end
  end

  def now_playing(token) do
    headers = @json_headers ++ authorization_headers(token)

    case get("/me/player", headers) do
      {:ok, %{status: 204}} ->
        :not_playing

      {:ok, response} ->
        {:playing, Jason.decode!(response.body)}

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
end
