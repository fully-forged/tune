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
      thumbnails: %{
        large: @album_thumbnail
      }
    },
    artist: %Artist{
      name: @artist_name
    }
  }

  setup :verify_on_exit!

  # Missing test cases:
  #
  # - Logged in, song pauses
  # - Logged in, song resumes
  # - Error with profile
  # - Error with  now playing

  describe "logged out" do
    test "it displays not playing", %{conn: conn} do
      {:ok, page_live, disconnected_html} = live(conn, "/")

      login_required_message = "The application requires you to Login into your Spotify account."

      assert disconnected_html =~ login_required_message
      assert render(page_live) =~ login_required_message
    end
  end

  describe "logged in" do
    @session_id "example.user"
    @credentials %Ueberauth.Auth.Credentials{
      token: "example-token",
      refresh_token: "refresh-token"
    }

    setup %{conn: conn} do
      Tune.Spotify.SessionMock
      |> expect(:setup, 2, fn @session_id, @credentials -> :ok end)
      |> expect(:get_profile, 2, fn @session_id -> @profile end)

      [conn: init_test_session(conn, spotify_id: @session_id, spotify_credentials: @credentials)]
    end

    test "it displays not playing", %{conn: conn} do
      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn @session_id -> :not_playing end)

      {:ok, page_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ "Not playing."
      assert render(page_live) =~ "Not playing."
    end

    test "it displays a song playing", %{conn: conn} do
      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn @session_id -> {:playing, @now_playing} end)

      {:ok, page_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ @song_title
      assert render(page_live) =~ @song_title
    end

    test "it updates when the song changes", %{conn: conn} do
      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn @session_id -> {:playing, @now_playing} end)

      {:ok, page_live, _html} = live(conn, "/")

      now_playing = {:playing, %{@now_playing | name: "Another song"}}

      send(page_live.pid, now_playing)

      render(page_live) =~ "Another song"
    end
  end
end
