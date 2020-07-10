defmodule TuneWeb.LoggedInTest do
  use TuneWeb.ConnCase

  alias Tune.{Fixtures, Generators}

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  setup %{conn: conn} do
    session_id = Fixtures.session_id()
    credentials = Fixtures.credentials()

    Tune.Spotify.SessionMock
    |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
    |> expect(:get_profile, 2, fn ^session_id -> Fixtures.profile() end)

    [
      session_id: session_id,
      conn: init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
    ]
  end

  describe "mini player" do
    test "it displays not playing", %{conn: conn, session_id: session_id} do
      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> :not_playing end)

      {:ok, explorer_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ "Not playing."
      assert render(explorer_live) =~ "Not playing."
    end

    test "it displays a song playing", %{conn: conn, session_id: session_id} do
      track = pick_track()

      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> {:playing, track} end)

      {:ok, explorer_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ track.name
      assert render(explorer_live) =~ track.name
    end

    test "it updates when the song changes", %{conn: conn, session_id: session_id} do
      track = pick_track()

      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> {:playing, track} end)

      {:ok, explorer_live, _html} = live(conn, "/")

      now_playing = {:playing, %{track | name: "Another song"}}

      send(explorer_live.pid, now_playing)

      render(explorer_live) =~ "Another song"
    end
  end

  describe "search" do
    test "it defaults to searching for tracks", %{conn: conn, session_id: session_id} do
      track = pick_track()

      search_results = %{
        tracks: [track]
      }

      track_name = track.name

      if String.length(track_name) >= 3 do
        Tune.Spotify.SessionMock
        |> expect(:now_playing, 2, fn ^session_id -> :not_playing end)
        |> expect(:search, 2, fn ^session_id, ^track_name, [:track] -> {:ok, search_results} end)

        {:ok, explorer_live, html} = live(conn, "/?q=#{URI.encode(track_name)}")
        assert html =~ track_name
        assert html =~ track.artist.name

        assert render(explorer_live) =~ track_name
        assert render(explorer_live) =~ track.artist.name
      else
        Tune.Spotify.SessionMock
        |> expect(:now_playing, 2, fn ^session_id -> :not_playing end)

        {:ok, explorer_live, html} = live(conn, "/?q=#{URI.encode(track_name)}")
        refute html =~ track_name
        refute html =~ track.artist.name

        refute render(explorer_live) =~ track_name
        refute render(explorer_live) =~ track.artist.name
      end
    end
  end

  defp pick_track do
    [track] =
      Generators.track()
      |> Enum.take(1)

    track
  end
end
