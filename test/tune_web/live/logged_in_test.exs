defmodule TuneWeb.LoggedInTest do
  use TuneWeb.ConnCase
  use ExUnitProperties

  alias Tune.Generators
  alias Tune.Spotify.Schema.Player

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  describe "mini player" do
    test "it displays not playing", %{conn: conn} do
      # Not necessary to run this as a property, as it doesn't have much
      # expected variation - we just need some basic working data for the
      # current session and user.
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())
      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

      Tune.Spotify.SessionMock
      |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
      |> expect(:get_profile, 2, fn ^session_id -> profile end)
      |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)

      {:ok, explorer_live, disconnected_html} = live(conn, "/")

      assert disconnected_html =~ "Not playing"
      assert render(explorer_live) =~ "Not playing"
    end

    property "it displays an item playing", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.item()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

        Tune.Spotify.SessionMock
        |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
        |> expect(:get_profile, 2, fn ^session_id -> profile end)
        |> expect(:now_playing, 2, fn ^session_id ->
          %Player{status: :playing, item: item, progress_ms: item.duration_ms - 100}
        end)

        {:ok, explorer_live, disconnected_html} = live(conn, "/")

        escaped_item_name =
          item.name
          |> Phoenix.HTML.html_escape()
          |> Phoenix.HTML.safe_to_string()

        assert disconnected_html =~ escaped_item_name
        assert render(explorer_live) =~ escaped_item_name
      end
    end

    property "it updates when the item changes", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.item(),
              second_item <- Generators.item()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        now_playing = %Player{status: :playing, item: item, progress_ms: item.duration_ms - 100}

        Tune.Spotify.SessionMock
        |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
        |> expect(:get_profile, 2, fn ^session_id -> profile end)
        |> expect(:now_playing, 2, fn ^session_id -> now_playing end)

        {:ok, explorer_live, disconnected_html} = live(conn, "/")

        escaped_item_name =
          item.name
          |> Phoenix.HTML.html_escape()
          |> Phoenix.HTML.safe_to_string()

        assert disconnected_html =~ escaped_item_name
        assert render(explorer_live) =~ escaped_item_name

        now_playing = %{now_playing | item: second_item}

        send(explorer_live.pid, now_playing)

        escaped_item_name =
          second_item.name
          |> Phoenix.HTML.html_escape()
          |> Phoenix.HTML.safe_to_string()

        render(explorer_live) =~ escaped_item_name
      end
    end
  end

  describe "search" do
    test "it suggests to perform a search", %{conn: conn} do
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())

      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

      Tune.Spotify.SessionMock
      |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
      |> expect(:get_profile, 2, fn ^session_id -> profile end)
      |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)

      {:ok, explorer_live, html} = live(conn, "/")
      assert html =~ "Try and search for a song you love"
      assert html =~ "Try and search for a song you love"

      assert render(explorer_live) =~ "Try and search for a song you love"
      assert render(explorer_live) =~ "Try and search for a song you love"
    end

    test "it shows a notice when there are no results", %{conn: conn} do
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())

      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

      search_results = %{
        tracks: []
      }

      Tune.Spotify.SessionMock
      |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
      |> expect(:get_profile, 2, fn ^session_id -> profile end)
      |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)
      |> expect(:search, 2, fn ^session_id, "example search", [types: [:track], limit: 32] ->
        {:ok, search_results}
      end)

      {:ok, explorer_live, html} = live(conn, "/?q=example+search")
      assert html =~ "No results"
      assert html =~ "No results"

      assert render(explorer_live) =~ "No results"
      assert render(explorer_live) =~ "No results"
    end

    property "it defaults to searching for tracks", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              tracks <- uniq_list_of(Generators.track(), min_length: 1, max_length: 32)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

        search_results = %{
          tracks: tracks
        }

        track = Enum.random(tracks)
        track_name = track.name

        Tune.Spotify.SessionMock
        |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
        |> expect(:get_profile, 2, fn ^session_id -> profile end)
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
  end
end
