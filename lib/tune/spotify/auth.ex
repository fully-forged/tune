defmodule Tune.Spotify.Auth do
  @moduledoc false

  @type credentials :: %{spotify_client_id: String.t(), spotify_client_secret: String.t()}

  @spec configure!(credentials) :: :ok
  def configure!(%{
        spotify_client_id: client_id,
        spotify_client_secret: client_secret
      }) do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Spotify.OAuth,
      client_id: client_id,
      client_secret: client_secret
    )
  end

  @spec base64_encoded_credentials() :: String.t() | no_return()
  def base64_encoded_credentials do
    ueberauth_spotify_config =
      Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Spotify.OAuth)

    client_id = Keyword.fetch!(ueberauth_spotify_config, :client_id)
    client_secret = Keyword.fetch!(ueberauth_spotify_config, :client_secret)

    Base.encode64(client_id <> ":" <> client_secret)
  end
end
