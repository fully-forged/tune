defmodule Tune.Spotify.Auth do
  def configure! do
    {client_id, client_secret} = get_credentials_from_env!()

    Application.put_env(:ueberauth, Ueberauth.Strategy.Spotify.OAuth,
      client_id: client_id,
      client_secret: client_secret
    )
  end

  def base64_encoded_credentials do
    {client_id, client_secret} = get_credentials_from_env!()

    Base.encode64(client_id <> ":" <> client_secret)
  end

  defp get_credentials_from_env! do
    {System.get_env("SPOTIFY_CLIENT_ID"), System.get_env("SPOTIFY_CLIENT_SECRET")}
  end
end
