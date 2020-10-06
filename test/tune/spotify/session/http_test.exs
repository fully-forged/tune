defmodule Tune.Spotify.Session.HTTPTest do
  use ExUnit.Case
  use ExUnitProperties

  import Mox
  import Eventually

  alias Tune.{Generators, Spotify.Schema, Spotify.Session.HTTP, Spotify.Client}
  alias Schema.{Album, Artist, Episode, Player, Playlist, Show, Track}

  @default_timeouts %{
    refresh: 200,
    retry: 100,
    inactivity: 100
  }

  setup [:set_mox_global, :verify_on_exit!]

  describe "auth/profile" do
    @tag capture_log: true
    property "with an expired token, the process stops" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              max_runs: 5
            ) do
        token = credentials.token

        Client.Mock
        |> expect(:get_profile, 1, fn ^token -> {:error, :invalid_token} end)

        Process.flag(:trap_exit, true)

        assert {:ok, session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert_receive {:EXIT, ^session_pid, :invalid_token}
      end
    end

    property "with an expired token, the process refreshes the token and retries" do
      check all(
              old_credentials <- Generators.credentials(),
              new_credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        expect_profile_with_token_refresh(old_credentials, new_credentials)
        expect_profile(new_credentials.token, profile)
        expect_nothing_playing(new_credentials.token)
        expect_no_devices(new_credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, old_credentials, timeouts: @default_timeouts)

        assert profile == HTTP.get_profile(session_id)
      end
    end

    property "with a transient network error, the process retries" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        expect_profile_with_network_error(credentials.token)
        expect_profile(credentials.token, profile)
        expect_nothing_playing(credentials.token)
        expect_no_devices(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert_eventually profile == HTTP.get_profile(session_id)
      end
    end

    property "it fetches the user profile" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        expect_profile(credentials.token, profile)
        expect_nothing_playing(credentials.token)
        expect_no_devices(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert profile == HTTP.get_profile(session_id)
      end
    end
  end

  describe "player" do
    property "it returns the player token" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        expect_profile(credentials.token, profile)
        expect_nothing_playing(credentials.token)
        expect_no_devices(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert :ok == HTTP.subscribe(session_id)

        player_token = credentials.token

        assert {:ok, player_token} == HTTP.get_player_token(session_id)
        assert_receive {:player_token, ^player_token}
      end
    end

    property "it fetches the now playing information" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        player = expect_item_playing(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert :ok == HTTP.subscribe(session_id)

        assert player == HTTP.now_playing(session_id)
        assert_receive {:now_playing, ^player}
      end
    end

    property "it fetches devices information" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert :ok == HTTP.subscribe(session_id)

        assert [device] == HTTP.get_devices(session_id)
        assert_receive {:devices, [^device]}
      end
    end

    property "toggling play when paused" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item paused

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_paused(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Toggle play/pause

        expect_play(credentials.token)
        player = expect_item_playing(credentials.token, item, device)

        assert :ok == HTTP.toggle_play(session_id)
        assert_eventually player == HTTP.now_playing(session_id)
      end
    end

    property "toggling play when playing" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item paused

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_playing(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Toggle play/pause
        expect_pause(credentials.token)
        player = expect_item_paused(credentials.token, item, device)

        assert :ok == HTTP.toggle_play(session_id)
        assert_eventually player == HTTP.now_playing(session_id)
      end
    end

    property "play an item" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              old_item <- Generators.playable_item(),
              new_item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session playing an item

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_playing(credentials.token, old_item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Play another item

        expect_play(credentials.token, new_item.uri)
        player = expect_item_playing(credentials.token, new_item, device)

        assert :ok == HTTP.play(session_id, new_item.uri)
        assert_eventually player == HTTP.now_playing(session_id)
      end
    end

    property "play an item with context" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              old_item <- Generators.playable_item(),
              new_item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session playing an item

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_playing(credentials.token, old_item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Play another item with context

        context_uri =
          case new_item do
            %Episode{show: show} -> show.uri
            %Track{album: album} -> album.uri
          end

        expect_play(credentials.token, new_item.uri, context_uri)
        player = expect_item_playing(credentials.token, new_item, device)

        assert :ok == HTTP.play(session_id, new_item.uri, context_uri)
        assert_eventually player == HTTP.now_playing(session_id)
      end
    end

    property "next/prev" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              next_item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item playing

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_playing(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Skip to next item

        expect_next(credentials.token)
        player = expect_item_playing(credentials.token, next_item, device)
        assert :ok == HTTP.next(session_id)
        assert_eventually player == HTTP.now_playing(session_id)

        # Skip to prev item

        expect_prev(credentials.token)
        player = expect_item_playing(credentials.token, item, device)
        assert :ok == HTTP.prev(session_id)
        assert_eventually player == HTTP.now_playing(session_id)
      end
    end

    property "set volume" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item playing

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_item_playing(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Set volume to a 100

        expect_set_volume(credentials.token, 100)
        expect_item_playing(credentials.token, item, device)

        assert :ok == HTTP.set_volume(session_id, 100)
      end
    end

    property "seek" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item playing

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        player = expect_item_playing(credentials.token, item, device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Seek a position in the song

        new_position_ms = max(player.progress_ms + 100, player.item.duration_ms - 100)

        expect_seek(credentials.token, new_position_ms)
        expect_item_playing(credentials.token, item, device)

        assert :ok == HTTP.seek(session_id, new_position_ms)
      end
    end

    property "transfer playback" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- Generators.playable_item(),
              old_device <- Generators.device(),
              new_device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item playing on the old device

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [old_device, new_device])
        expect_item_playing(credentials.token, item, old_device)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Transfer playback to the new device

        expect_transfer_playback(credentials.token, new_device.id)
        assert :ok == HTTP.transfer_playback(session_id, new_device.id)
      end
    end

    property "get and refresh devices" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              old_device <- Generators.device(),
              new_device <- Generators.device(),
              max_runs: 5
            ) do
        # Start a session with an item playing on the old device

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [old_device])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get initial devices

        assert [old_device] == HTTP.get_devices(session_id)

        # Change available devices and force a refresh

        expect_devices(credentials.token, [new_device])

        assert :ok == HTTP.refresh_devices(session_id)
        assert [new_device] == HTTP.get_devices(session_id)
      end
    end

    property "auto-refresh of data" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              old_device <- Generators.device(),
              new_device <- Generators.device(),
              old_item <- Generators.playable_item(),
              new_item <- Generators.playable_item(),
              max_runs: 5
            ) do
        # Start a session with the old item playing on the old device

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [old_device])
        old_player = expect_item_playing(credentials.token, old_item, old_device)

        timeouts =
          @default_timeouts
          |> Map.put(:inactivity, 300)

        assert {:ok, _session_pid} = HTTP.start_link(session_id, credentials, timeouts: timeouts)

        # Get initial devices

        assert [old_device] == HTTP.get_devices(session_id)
        assert old_player == HTTP.now_playing(session_id)

        # Auto refresh cycle returns different playing item and devices

        expect_devices(credentials.token, [new_device])
        new_player = expect_item_playing(credentials.token, new_item, new_device)

        assert_eventually [new_device] == HTTP.get_devices(session_id)
        assert_eventually new_player == HTTP.now_playing(session_id)
      end
    end
  end

  describe "search" do
    property "it returns categorized results" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              search_type <- Generators.search_type(),
              query <- Generators.search_query(),
              items <-
                uniq_list_of(Generators.searchable(search_type), min_length: 0, max_length: 24)
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Perform search

        search_results =
          expect_search_results(credentials.token, query, items,
            search_type: search_type,
            limit: 24,
            offset: 0
          )

        assert {:ok, search_results} ==
                 HTTP.search(session_id, query, types: [search_type], limit: 24, offset: 0)
      end
    end
  end

  describe "content" do
    property "it returns an item" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              item <- one_of([Generators.item_with_details(), Generators.playlist()])
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get item

        case item do
          %Album{id: id} ->
            expect_get_album(credentials.token, item)
            assert {:ok, item} == HTTP.get_album(session_id, id)

          %Artist{id: id} ->
            expect_get_artist(credentials.token, item)
            assert {:ok, item} == HTTP.get_artist(session_id, id)

          %Playlist{id: id} ->
            expect_get_playlist(credentials.token, item)
            assert {:ok, item} == HTTP.get_playlist(session_id, id)

          %Show{id: id} ->
            expect_get_show(credentials.token, item)
            assert {:ok, item} == HTTP.get_show(session_id, id)
        end
      end
    end

    property "it returns an artist's albums" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              artist_id <- Generators.id(),
              albums <- uniq_list_of(Generators.album(), min_length: 1, max_length: 24),
              max_runs: 5
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get an artist's albums

        opts = [limit: 10, offset: 0]

        expect_get_artist_albums(credentials.token, artist_id, albums, opts)

        assert {:ok, albums} == HTTP.get_artist_albums(session_id, artist_id, opts)
      end
    end

    property "it returns a show's episodes" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              show_id <- Generators.id(),
              episodes <- uniq_list_of(Generators.episode(), min_length: 1, max_length: 24),
              max_runs: 5
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get a show's episodes

        expect_get_episodes(credentials.token, show_id, episodes)

        assert {:ok, episodes} == HTTP.get_episodes(session_id, show_id)
      end
    end

    property "it returns recommendations from artists" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              artist_ids <- uniq_list_of(Generators.id(), max_length: 24),
              recommended_tracks <-
                uniq_list_of(Generators.track(), min_length: 1, max_length: 24),
              max_runs: 5
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get recommendations

        expect_get_recommendations_from_artists(credentials.token, artist_ids, recommended_tracks)

        assert {:ok, recommended_tracks} ==
                 HTTP.get_recommendations_from_artists(session_id, artist_ids)
      end
    end

    property "it returns recently played tracks" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              recently_played_tracks <-
                uniq_list_of(Generators.track(), min_length: 1, max_length: 24),
              max_runs: 5
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get recently played tracks
        recently_played_tracks_options = [limit: 50]

        expect_recently_played_tracks(
          credentials.token,
          recently_played_tracks_options,
          recently_played_tracks
        )

        assert {:ok, recently_played_tracks} ==
                 HTTP.recently_played_tracks(session_id, recently_played_tracks_options)
      end
    end

    property "it returns top tracks" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              top_tracks <-
                uniq_list_of(Generators.track(), min_length: 1, max_length: 24),
              max_runs: 5
            ) do
        # Start a session

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [])
        expect_nothing_playing(credentials.token)

        assert {:ok, _session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        # Get top tracks
        top_tracks_options = [time_range: "short_term", limit: 24, offset: 0]

        expect_top_tracks(credentials.token, top_tracks_options, top_tracks)

        assert {:ok, top_tracks} == HTTP.top_tracks(session_id, top_tracks_options)
      end
    end
  end

  defp expect_profile(token, profile) do
    Client.Mock
    |> expect(:get_profile, 1, fn ^token -> {:ok, profile} end)
  end

  defp expect_profile_with_token_refresh(old_credentials, new_credentials) do
    old_token = old_credentials.token
    refresh_token = old_credentials.refresh_token

    Client.Mock
    |> expect(:get_profile, 1, fn ^old_token -> {:error, :expired_token} end)
    |> expect(:get_token, 1, fn ^refresh_token -> {:ok, new_credentials} end)
  end

  defp expect_profile_with_network_error(token) do
    Client.Mock
    |> expect(:get_profile, 1, fn ^token -> {:error, :nxdomain} end)
  end

  defp expect_nothing_playing(token) do
    Client.Mock
    |> expect(:now_playing, 1, fn ^token -> {:ok, %Player{status: :not_playing}} end)
  end

  defp expect_no_devices(token) do
    Client.Mock
    |> expect(:get_devices, 1, fn ^token -> {:ok, []} end)
  end

  defp expect_devices(token, devices) do
    Client.Mock
    |> expect(:get_devices, 1, fn ^token -> {:ok, devices} end)
  end

  defp expect_item_playing(token, item, device) do
    player = %Player{
      status: :playing,
      item: item,
      progress_ms: item.duration_ms - 100,
      device: device
    }

    Client.Mock
    |> expect(:now_playing, 1, fn ^token -> {:ok, player} end)

    player
  end

  defp expect_item_paused(token, item, device) do
    player = %Player{
      status: :paused,
      item: item,
      progress_ms: item.duration_ms - 100,
      device: device
    }

    Client.Mock
    |> expect(:now_playing, 1, fn ^token -> {:ok, player} end)

    player
  end

  defp expect_play(token) do
    Client.Mock
    |> expect(:play, 1, fn ^token -> :ok end)
  end

  defp expect_play(token, item_uri) do
    Client.Mock
    |> expect(:play, 1, fn ^token, ^item_uri -> :ok end)
  end

  defp expect_play(token, item_uri, context_uri) do
    Client.Mock
    |> expect(:play, 1, fn ^token, ^item_uri, ^context_uri -> :ok end)
  end

  defp expect_pause(token) do
    Client.Mock
    |> expect(:pause, 1, fn ^token -> :ok end)
  end

  defp expect_next(token) do
    Client.Mock
    |> expect(:next, 1, fn ^token -> :ok end)
  end

  defp expect_prev(token) do
    Client.Mock
    |> expect(:prev, 1, fn ^token -> :ok end)
  end

  defp expect_set_volume(token, volume_percent) do
    Client.Mock
    |> expect(:set_volume, 1, fn ^token, ^volume_percent -> :ok end)
  end

  defp expect_seek(token, position_ms) do
    Client.Mock
    |> expect(:seek, 1, fn ^token, ^position_ms -> :ok end)
  end

  defp expect_transfer_playback(token, device_id) do
    Client.Mock
    |> expect(:transfer_playback, 1, fn ^token, ^device_id -> :ok end)
  end

  defp expect_search_results(token, query, items, opts) do
    search_type = Keyword.fetch!(opts, :search_type)
    limit = Keyword.get(opts, :limit, 24)
    offset = Keyword.get(opts, :offset, 0)

    search_results = %{
      search_type => %{
        items: items,
        total: Enum.count(items)
      }
    }

    Client.Mock
    |> expect(:search, 1, fn ^token,
                             ^query,
                             [types: [^search_type], limit: ^limit, offset: ^offset] ->
      {:ok, search_results}
    end)

    search_results
  end

  defp expect_get_artist(token, artist) do
    artist_id = artist.id

    Client.Mock
    |> expect(:get_artist, fn ^token, ^artist_id -> {:ok, artist} end)
  end

  defp expect_get_album(token, album) do
    album_id = album.id

    Client.Mock
    |> expect(:get_album, fn ^token, ^album_id -> {:ok, album} end)
  end

  defp expect_get_show(token, show) do
    show_id = show.id

    Client.Mock
    |> expect(:get_show, fn ^token, ^show_id -> {:ok, show} end)
  end

  defp expect_get_playlist(token, playlist) do
    playlist_id = playlist.id

    Client.Mock
    |> expect(:get_playlist, fn ^token, ^playlist_id -> {:ok, playlist} end)
  end

  defp expect_get_artist_albums(token, artist_id, albums, opts) do
    Client.Mock
    |> expect(:get_artist_albums, fn ^token, ^artist_id, ^opts -> {:ok, albums} end)
  end

  defp expect_get_episodes(token, show_id, episodes) do
    Client.Mock
    |> expect(:get_episodes, fn ^token, ^show_id -> {:ok, episodes} end)
  end

  defp expect_get_recommendations_from_artists(token, artist_ids, recommended_tracks) do
    Client.Mock
    |> expect(:get_recommendations_from_artists, fn ^token, ^artist_ids ->
      {:ok, recommended_tracks}
    end)
  end

  defp expect_top_tracks(token, top_tracks_options, top_tracks) do
    Client.Mock
    |> expect(:top_tracks, fn ^token, ^top_tracks_options -> {:ok, top_tracks} end)
  end

  defp expect_recently_played_tracks(token, recently_played_tracks_options, top_tracks) do
    Client.Mock
    |> expect(:recently_played_tracks, fn ^token, ^recently_played_tracks_options ->
      {:ok, top_tracks}
    end)
  end
end
