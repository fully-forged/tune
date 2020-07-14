defmodule TuneWeb.LoggedInTest do
  use TuneWeb.ConnCase

  alias Tune.Generators
  alias Tune.Spotify.Schema.Player

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  setup %{conn: conn} do
    [session_id] =
      Generators.session_id()
      |> Enum.take(1)

    [credentials] =
      Generators.credentials()
      |> Enum.take(1)

    [profile] =
      Generators.profile()
      |> Enum.take(1)

    Tune.Spotify.SessionMock
    |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
    |> expect(:get_profile, 2, fn ^session_id -> profile end)

    [
      session_id: session_id,
      conn: init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
    ]
  end

  describe "mini player" do
    test "it displays not playing", %{conn: conn, session_id: session_id} do
      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)

      {:ok, explorer_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ "Not playing"
      assert render(explorer_live) =~ "Not playing"
    end

    test "it displays an item playing", %{conn: conn, session_id: session_id} do
      item = pick_item()

      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id ->
        %Player{status: :playing, item: item, progress_ms: item.duration_ms - 100}
      end)

      {:ok, explorer_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ item.name
      assert render(explorer_live) =~ item.name
    end

    test "it updates when the item changes", %{conn: conn, session_id: session_id} do
      item = pick_track()
      now_playing = %Player{status: :playing, item: item, progress_ms: item.duration_ms - 100}

      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> now_playing end)

      {:ok, explorer_live, _html} = live(conn, "/")

      new_track = %{item | name: "Another item"}
      now_playing = %{now_playing | item: new_track}

      send(explorer_live.pid, now_playing)

      render(explorer_live) =~ "Another item"
    end
  end

  describe "search" do
    test "it defaults to searching for tracks", %{conn: conn, session_id: session_id} do
      track = pick_track()

      search_results = %{
        tracks: [track]
      }

      track_name = track.name

      Tune.Spotify.SessionMock
      |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)
      |> expect(:search, 2, fn ^session_id, ^track_name, [types: [:track], limit: 32] ->
        {:ok, search_results}
      end)

      {:ok, explorer_live, html} = live(conn, "/?q=#{URI.encode(track_name)}")
      assert html =~ track_name
      assert html =~ track.artist.name

      assert render(explorer_live) =~ track_name
      assert render(explorer_live) =~ track.artist.name
    end
  end

  defp pick_item do
    Generators.item()
    |> Enum.take(1)
    |> hd()
  end

  defp pick_track do
    Generators.track()
    |> Enum.take(1)
    |> hd()
  end
end
