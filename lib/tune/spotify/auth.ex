defmodule Tune.Spotify.Auth do
  def configure! do
    client_id = System.get_env("SPOTIFY_CLIENT_ID")
    client_secret = System.get_env("SPOTIFY_CLIENT_SECRET")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Spotify.OAuth,
      client_id: client_id,
      client_secret: client_secret
    )
  end

  def base64_encoded_credentials do
    client_id = System.get_env("SPOTIFY_CLIENT_ID")
    client_secret = System.get_env("SPOTIFY_CLIENT_SECRET")

    Base.encode64(client_id <> ":" <> client_secret)
  end
end
