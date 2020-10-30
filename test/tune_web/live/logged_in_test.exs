defmodule TuneWeb.LoggedInTest do
  use TuneWeb.ConnCase
  use ExUnitProperties

  alias Tune.Duration
  alias Tune.Generators
  alias Tune.Spotify.Schema.{Album, Artist, Episode, Player, Show, Track}

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

      expect_successful_authentication(session_id, credentials, profile)
      expect_nothing_playing(session_id)
      expect_no_release_radar_playlist(session_id)

      {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

      assert html =~ "Not playing"
      assert render(explorer_live) =~ "Not playing"
    end

    property "it displays an item playing", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_item_playing(session_id, item, device)
        expect_no_release_radar_playlist(session_id)

        {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

        escaped_item_name = escape(item.name)

        assert html =~ escaped_item_name
        assert render(explorer_live) =~ escaped_item_name
      end
    end

    property "it updates when the item changes", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              second_item <- Generators.playable_item(),
              recently_played_tracks <- uniq_list_of(Generators.track(), max_length: 24),
              device <- Generators.device()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        player = expect_item_playing(session_id, item, device)
        expect_no_release_radar_playlist(session_id)

        {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

        escaped_item_name = escape(item.name)

        assert html =~ escaped_item_name
        assert render(explorer_live) =~ escaped_item_name

        new_player = %{player | item: second_item, progress_ms: second_item.duration_ms - 100}

        expect_single_recently_played_tracks(session_id, recently_played_tracks, 50)
        send(explorer_live.pid, {:now_playing, new_player})

        escaped_item_name = escape(second_item.name)

        render(explorer_live) =~ escaped_item_name
      end
    end

    property "it supports control operations", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.premium_profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              volume_percent <- Generators.volume_percent()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        player = expect_item_playing(session_id, item, device)
        expect_no_release_radar_playlist(session_id)

        {:ok, explorer_live, _html} = live(conn, Routes.explorer_path(conn, :suggestions))

        assert has_element?(explorer_live, "[data-test-status=playing]")

        Tune.Spotify.Session.Mock
        |> expect(:toggle_play, 1, fn ^session_id ->
          new_player = %{player | status: :paused}
          send(explorer_live.pid, {:now_playing, new_player})
          :ok
        end)

        assert explorer_live
               |> element("[data-test-control=play-pause]")
               |> render_click()

        assert has_element?(explorer_live, "[data-test-status=paused]")

        Tune.Spotify.Session.Mock
        |> expect(:next, 1, fn ^session_id -> :ok end)

        assert explorer_live
               |> element("[data-test-control=next]")
               |> render_click()

        Tune.Spotify.Session.Mock
        |> expect(:prev, 1, fn ^session_id -> :ok end)

        assert explorer_live
               |> element("[data-test-control=prev]")
               |> render_click()

        Tune.Spotify.Session.Mock
        |> expect(:set_volume, 1, fn ^session_id, ^volume_percent -> :ok end)

        assert explorer_live
               |> element("[data-test-control=volume]")
               |> render_hook("set_volume", %{"volume_percent" => volume_percent})

        new_position_ms = max(player.progress_ms + 100, player.item.duration_ms - 100)

        Tune.Spotify.Session.Mock
        |> expect(:seek, 1, fn ^session_id, ^new_position_ms -> :ok end)

        assert explorer_live
               |> element("[data-test-control=progress]")
               |> render_hook("seek", %{"position_ms" => new_position_ms})
      end
    end

    property "hides controls for users with a free subscription", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.free_profile(),
              item <- Generators.playable_item(),
              device <- Generators.device()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

        expect_successful_authentication(session_id, credentials, profile)
        expect_item_playing(session_id, item, device)
        expect_no_release_radar_playlist(session_id)

        {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

        escaped_item_name = escape(item.name)
        assert html =~ escaped_item_name

        assert explorer_live
               |> element("[data-test-control=progress]")
               |> render() =~ ~s(data-premium="false")

        refute has_element?(explorer_live, "[data-test-control=next]")
        refute has_element?(explorer_live, "[data-test-control=prev]")
        refute has_element?(explorer_live, "[data-test-control=play-pause]")
        refute has_element?(explorer_live, "[data-test-control=volume]")
      end
    end
  end

  describe "search" do
    test "it suggests to perform a search", %{conn: conn} do
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())

      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
      expect_successful_authentication(session_id, credentials, profile)
      expect_nothing_playing(session_id)

      {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :search))
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
      expect_successful_authentication(session_id, credentials, profile)
      expect_nothing_playing(session_id)

      search_results = %{
        track: %{
          items: [],
          total: 0
        }
      }

      Tune.Spotify.Session.Mock
      |> expect(:search, 2, fn ^session_id,
                               "example search",
                               [types: [:track], limit: 24, offset: 0] ->
        {:ok, search_results}
      end)

      {:ok, explorer_live, html} =
        live(conn, Routes.explorer_path(conn, :search, q: "example search"))

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
              tracks <- uniq_list_of(Generators.track(), min_length: 1, max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)

        search_results = %{
          track: %{
            items: tracks,
            total: Enum.count(tracks)
          }
        }

        track = Enum.random(tracks)
        track_name = track.name

        Tune.Spotify.Session.Mock
        |> expect(:search, 2, fn ^session_id,
                                 ^track_name,
                                 [types: [:track], limit: 24, offset: 0] ->
          {:ok, search_results}
        end)

        {:ok, explorer_live, html} =
          live(conn, Routes.explorer_path(conn, :search, q: track_name))

        escaped_track_name = escape(track_name)
        assert html =~ escaped_track_name
        assert render(explorer_live) =~ escaped_track_name

        for artist <- track.artists do
          escaped_artist_name = escape(artist.name)
          assert html =~ escaped_artist_name
          assert render(explorer_live) =~ escaped_artist_name
        end
      end
    end

    property "it supports searching for other types", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              search_type <- Generators.search_type(),
              items <-
                uniq_list_of(Generators.searchable(search_type), min_length: 1, max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)

        search_results = %{
          search_type => %{
            items: items,
            total: Enum.count(items)
          }
        }

        item = Enum.random(items)
        item_name = TuneWeb.SearchView.name(item)

        Tune.Spotify.Session.Mock
        |> expect(:search, 2, fn ^session_id,
                                 ^item_name,
                                 [types: [^search_type], limit: 24, offset: 0] ->
          {:ok, search_results}
        end)

        {:ok, explorer_live, html} =
          live(conn, Routes.explorer_path(conn, :search, q: item_name, type: search_type))

        escaped_item_name = escape(item_name)
        assert html =~ escaped_item_name
        assert render(explorer_live) =~ escaped_item_name

        author_names =
          case item do
            %Artist{name: name} -> [name]
            %Album{artists: artists} -> Enum.map(artists, & &1.name)
            %Track{artists: artists} -> Enum.map(artists, & &1.name)
            %Episode{publisher: publisher} -> [publisher.name]
            %Show{publisher: publisher} -> [publisher.name]
          end

        for author_name <- author_names do
          escaped_author_name = escape(author_name)
          assert html =~ escaped_author_name
          assert render(explorer_live) =~ escaped_author_name
        end
      end
    end

    property "it supports playing the searched item", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              search_type <- Generators.search_type(),
              items <-
                uniq_list_of(Generators.searchable(search_type), min_length: 1, max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)

        search_results = %{
          search_type => %{
            items: items,
            total: Enum.count(items)
          }
        }

        item = Enum.random(items)
        item_name = item.name
        item_uri = item.uri

        Tune.Spotify.Session.Mock
        |> expect(:search, 2, fn ^session_id,
                                 ^item_name,
                                 [types: [^search_type], limit: 24, offset: 0] ->
          {:ok, search_results}
        end)
        |> expect(:play, 1, fn ^session_id, ^item_uri -> :ok end)

        {:ok, explorer_live, _html} =
          live(conn, Routes.explorer_path(conn, :search, q: item_name, type: search_type))

        assert explorer_live
               |> element("[data-test-id=#{item.id}] .play-button")
               |> render_click()
      end
    end
  end

  describe "item details" do
    property "it displays artist information", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              artist <- Generators.artist(),
              albums <- uniq_list_of(Generators.album(), min_length: 1, max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)

        artist_id = artist.id

        Tune.Spotify.Session.Mock
        |> expect(:get_artist, 2, fn ^session_id, ^artist_id -> {:ok, artist} end)
        |> expect(:get_artist_albums, 2, fn ^session_id,
                                            ^artist_id,
                                            limit: 24,
                                            offset: 0,
                                            album_group: :all ->
          {:ok, %{albums: albums, total: Enum.count(albums)}}
        end)

        {:ok, explorer_live, html} =
          live(conn, Routes.explorer_path(conn, :artist_details, artist_id))

        for album <- albums do
          escaped_album_name = escape(album.name)

          assert html =~ escaped_album_name
          assert html =~ Album.release_year(album)
          assert render(explorer_live) =~ escaped_album_name
          assert render(explorer_live) =~ Album.release_year(album)
        end

        escaped_artist_name = escape(artist.name)

        assert html =~ escaped_artist_name
        assert render(explorer_live) =~ escaped_artist_name

        artist_uri = artist.uri

        Tune.Spotify.Session.Mock
        |> expect(:play, 1, fn ^session_id, ^artist_uri -> :ok end)

        assert explorer_live
               |> element("[data-test-id=#{artist.id}] > .details .play-button")
               |> render_click()

        [album] = Enum.take_random(albums, 1)
        album_uri = album.uri

        Tune.Spotify.Session.Mock
        |> expect(:play, 1, fn ^session_id, ^album_uri -> :ok end)

        assert explorer_live
               |> element("[data-test-id=#{album.id}] .play-button")
               |> render_click()
      end
    end

    property "it displays album information", %{conn: conn} do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              album <- Generators.album_with_tracks()
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)

        album_id = album.id

        Tune.Spotify.Session.Mock
        |> expect(:get_album, 2, fn ^session_id, ^album_id -> {:ok, album} end)

        {:ok, explorer_live, html} =
          live(conn, Routes.explorer_path(conn, :album_details, album_id))

        if Album.has_multiple_discs?(album) do
          for {disc_number, tracks} <- Album.grouped_tracks(album) do
            assert html =~ "Disc #{disc_number}"
            assert render(explorer_live) =~ "Disc #{disc_number}"

            for track <- tracks do
              escaped_track_name = escape(track.name)

              track_element =
                explorer_live
                |> element("[data-test-id=#{track.id}]")
                |> render()

              assert track_element =~ escaped_track_name
              assert track_element =~ Duration.hms(track.duration_ms)
            end
          end
        else
          [%{disc_number: disc_number} | _rest] = album.tracks
          refute html =~ "Disc #{disc_number}"
          refute render(explorer_live) =~ "Disc #{disc_number}"
        end

        for artist <- album.artists do
          escaped_artist_name = escape(artist.name)
          assert html =~ escaped_artist_name
          assert render(explorer_live) =~ escaped_artist_name
        end

        escaped_album_name = escape(album.name)
        assert html =~ escaped_album_name
        assert render(explorer_live) =~ escaped_album_name

        assert html =~ Album.release_year(album)
        assert render(explorer_live) =~ Album.release_year(album)

        assert html =~
                 album
                 |> Album.total_duration_ms()
                 |> Duration.human()

        assert render(explorer_live) =~
                 album
                 |> Album.total_duration_ms()
                 |> Duration.human()

        album_uri = album.uri

        Tune.Spotify.Session.Mock
        |> expect(:play, 1, fn ^session_id, ^album_uri -> :ok end)

        assert explorer_live
               |> element("[data-test-id=#{album.id}] .play-button")
               |> render_click()

        [track] = Enum.take_random(album.tracks, 1)
        track_uri = track.uri

        Tune.Spotify.Session.Mock
        |> expect(:play, 1, fn ^session_id, ^track_uri, ^album_uri -> :ok end)

        assert explorer_live
               |> element("[data-test-id=#{track.id}] .name")
               |> render_click()
      end
    end
  end

  describe "suggestions" do
    test "without release radar playlist", %{conn: conn} do
      # Not necessary to run this as a property, as it doesn't have much
      # expected variation - we just need some basic working data for the
      # current session and user.
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())
      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

      expect_successful_authentication(session_id, credentials, profile)
      expect_nothing_playing(session_id)
      expect_no_release_radar_playlist(session_id)

      {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

      assert html =~ "Cannot display Release Radar - Make sure you have access to the playlist."

      assert render(explorer_live) =~
               "Cannot display Release Radar - Make sure you have access to the playlist."
    end

    property "with release radar playlist", %{conn: conn} do
      top_tracks_limit = 24
      time_range = "short_term"

      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              release_radar_playlist <- Generators.playlist("Release Radar"),
              top_tracks <- uniq_list_of(Generators.track(), max_length: 24),
              recently_played_tracks <- uniq_list_of(Generators.track(), max_length: 24),
              recommended_tracks <- uniq_list_of(Generators.track(), max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)
        expect_release_radar_playlist(session_id, release_radar_playlist)

        expect_top_tracks(session_id, top_tracks, top_tracks_limit, time_range)
        expect_recently_played_tracks(session_id, recently_played_tracks, 50)

        artist_ids = Track.artist_ids(top_tracks)
        expect_recommendations_from_artists(session_id, artist_ids, recommended_tracks)

        {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

        assert html =~ "Release Radar"
        assert render(explorer_live) =~ "Release Radar"

        for track <- release_radar_playlist.tracks do
          escaped_album_name = escape(track.album.name)
          assert html =~ escaped_album_name
          assert render(explorer_live) =~ escaped_album_name

          for artist <- track.artists do
            escaped_artist_name = escape(artist.name)
            assert html =~ escaped_artist_name
            assert render(explorer_live) =~ escaped_artist_name
          end
        end
      end
    end

    property "with top albums, recently played albums and recommended tracks", %{conn: conn} do
      top_tracks_limit = 24
      time_range = "short_term"

      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              release_radar_playlist <- Generators.playlist("Release Radar"),
              top_tracks <- uniq_list_of(Generators.track(), max_length: 24),
              recently_played_tracks <- uniq_list_of(Generators.track(), max_length: 24),
              recommended_tracks <- uniq_list_of(Generators.track(), max_length: 24)
            ) do
        conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

        expect_successful_authentication(session_id, credentials, profile)
        expect_nothing_playing(session_id)
        expect_release_radar_playlist(session_id, release_radar_playlist)

        expect_top_tracks(session_id, top_tracks, top_tracks_limit, time_range)
        expect_recently_played_tracks(session_id, recently_played_tracks, 50)

        artist_ids = Track.artist_ids(top_tracks)
        expect_recommendations_from_artists(session_id, artist_ids, recommended_tracks)

        {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

        assert html =~ "Top Albums"
        assert html =~ "Recommended Tracks"
        assert render(explorer_live) =~ "Top Albums"
        assert render(explorer_live) =~ "Recommended Tracks"

        for album <- Album.from_tracks(top_tracks) do
          escaped_album_name = escape(album.name)
          assert html =~ escaped_album_name
          assert render(explorer_live) =~ escaped_album_name

          for artist <- album.artists do
            escaped_artist_name = escape(artist.name)
            assert html =~ escaped_artist_name
            assert render(explorer_live) =~ escaped_artist_name
          end
        end

        for album <- Album.from_tracks(recently_played_tracks) do
          escaped_album_name = escape(album.name)
          assert html =~ escaped_album_name
          assert render(explorer_live) =~ escaped_album_name

          for artist <- album.artists do
            escaped_artist_name = escape(artist.name)
            assert html =~ escaped_artist_name
            assert render(explorer_live) =~ escaped_artist_name
          end
        end

        for track <- recommended_tracks do
          escaped_track_name = escape(track.name)
          assert html =~ escaped_track_name
          assert render(explorer_live) =~ escaped_track_name

          for artist <- track.artists do
            escaped_artist_name = escape(artist.name)
            assert html =~ escaped_artist_name
            assert render(explorer_live) =~ escaped_artist_name
          end
        end
      end
    end

    test "with an error fetching top tracks", %{conn: conn} do
      # Not necessary to run this as a property, as it doesn't have much
      # expected variation - we just need some basic working data for the
      # current session and user.
      session_id = pick(Generators.session_id())
      credentials = pick(Generators.credentials())
      profile = pick(Generators.profile())
      release_radar_playlist = pick(Generators.playlist("Release Radar"))
      conn = init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)

      top_tracks_limit = 24
      time_range = "short_term"

      expect_successful_authentication(session_id, credentials, profile)
      expect_nothing_playing(session_id)
      expect_release_radar_playlist(session_id, release_radar_playlist)

      Tune.Spotify.Session.Mock
      |> expect(:top_tracks, 2, fn ^session_id,
                                   [limit: ^top_tracks_limit, time_range: ^time_range] ->
        {:error, 403}
      end)

      {:ok, explorer_live, html} = live(conn, Routes.explorer_path(conn, :suggestions))

      assert html =~ "Cannot display top albums."
      assert render(explorer_live) =~ "Cannot display top albums."
    end
  end

  defp escape(s) do
    s
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp expect_successful_authentication(session_id, credentials, profile) do
    Tune.Spotify.Session.Mock
    |> expect(:setup, 3, fn ^session_id, ^credentials -> :ok end)
    |> expect(:get_profile, 3, fn ^session_id -> profile end)
    |> expect(:get_devices, 2, fn ^session_id -> [] end)
    |> expect(:get_player_token, 2, fn ^session_id -> {:ok, credentials.token} end)
    |> expect(:subscribe, 1, fn ^session_id -> :ok end)
  end

  defp expect_nothing_playing(session_id) do
    Tune.Spotify.Session.Mock
    |> expect(:now_playing, 2, fn ^session_id -> %Player{status: :not_playing} end)
  end

  defp expect_item_playing(session_id, item, device) do
    player = %Player{
      status: :playing,
      item: item,
      progress_ms: item.duration_ms - 100,
      device: device
    }

    Tune.Spotify.Session.Mock
    |> expect(:now_playing, 2, fn ^session_id -> player end)

    player
  end

  defp expect_no_release_radar_playlist(session_id) do
    Tune.Spotify.Session.Mock
    |> expect(:search, 2, fn ^session_id, "Release Radar", [types: [:playlist], limit: 1] ->
      {:ok, %{playlists: %{items: [], total: 0}}}
    end)
  end

  defp expect_release_radar_playlist(session_id, playlist) do
    playlist_id = playlist.id

    Tune.Spotify.Session.Mock
    |> expect(:search, 2, fn ^session_id, "Release Radar", [types: [:playlist], limit: 1] ->
      {:ok, %{playlists: %{items: [playlist], total: 1}}}
    end)
    |> expect(:get_playlist, 2, fn ^session_id, ^playlist_id ->
      {:ok, playlist}
    end)
  end

  defp expect_top_tracks(session_id, top_tracks, limit, time_range) do
    Tune.Spotify.Session.Mock
    |> expect(:top_tracks, 2, fn ^session_id, [limit: ^limit, time_range: ^time_range] ->
      {:ok, top_tracks}
    end)
  end

  defp expect_recently_played_tracks(session_id, recently_played_tracks, limit) do
    Tune.Spotify.Session.Mock
    |> expect(:recently_played_tracks, 2, fn ^session_id, [limit: ^limit] ->
      {:ok, recently_played_tracks}
    end)
  end

  defp expect_single_recently_played_tracks(session_id, recently_played_tracks, limit) do
    Tune.Spotify.Session.Mock
    |> expect(:recently_played_tracks, 1, fn ^session_id, [limit: ^limit] ->
      {:ok, recently_played_tracks}
    end)
  end

  defp expect_recommendations_from_artists(session_id, artist_ids, recommended_tracks) do
    Tune.Spotify.Session.Mock
    |> expect(:get_recommendations_from_artists, 2, fn ^session_id, requested_artist_ids ->
      for requested_artist_id <- requested_artist_ids do
        assert requested_artist_id in artist_ids
      end

      {:ok, recommended_tracks}
    end)
  end
end
