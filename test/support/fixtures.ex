defmodule Tune.Fixtures do
  alias Tune.Spotify.Schema.{Album, Artist, Track, User}

  def avatar_url, do: "http://example.com/user.png"

  def profile do
    %User{
      name: "Example User",
      avatar_url: avatar_url()
    }
  end

  def album_thumbnail, do: "http://example.com/album.png"

  def track do
    %Track{
      id: "123456",
      uri: "spotify:track:123456",
      name: "Example song",
      album: %Album{
        name: "Example album",
        thumbnails: %{
          small: album_thumbnail(),
          medium: album_thumbnail(),
          large: album_thumbnail()
        }
      },
      artist: %Artist{
        name: "Example artist"
      }
    }
  end

  def session_id, do: "example.user"

  def credentials do
    %Ueberauth.Auth.Credentials{
      token: "example-token",
      refresh_token: "refresh-token"
    }
  end
end
