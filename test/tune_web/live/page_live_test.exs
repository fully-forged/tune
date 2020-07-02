defmodule TuneWeb.PageLiveTest do
  use TuneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mox

  alias Tune.{Album, Artist, Track, User}

  @avatar_url "http://example.com/user.png"
  @profile %User{
    name: "Example User",
    avatar_url: @avatar_url
  }

  @song_title "Example song"
  @artist_name "Example artist"
  @album_name "Example album"
  @album_thumbnail "http://example.com/album.png"
  @now_playing %Track{
    name: @song_title,
    album: %Album{
      name: @album_name,
      thumbnail: @album_thumbnail
    },
    artist: %Artist{
      name: @artist_name
    }
  }

  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    Tune.SpotifyMock
    |> expect(:setup, 2, fn "example-token" -> :ok end)
    |> expect(:get_profile, 2, fn "example-token" -> @profile end)
    |> expect(:now_playing, 2, fn "example-token" -> {:playing, @now_playing} end)

    {:ok, page_live, disconnected_html} =
      conn
      |> init_test_session(spotify_token: "example-token")
      |> live("/")

    assert disconnected_html =~ @song_title
    assert render(page_live) =~ @song_title
  end
end
