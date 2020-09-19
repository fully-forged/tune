defmodule Tune.Spotify.Session.HTTPTest do
  use ExUnit.Case
  use ExUnitProperties

  import Mox
  import Eventually

  alias Tune.{Generators, Spotify.Schema, Spotify.Session.HTTP, Spotify.Client}
  alias Schema.{Episode, Player, Track}

  @default_timeouts %{
    refresh: 200,
    retry: 100,
    inactivity: 100
  }

  setup [:set_mox_global, :verify_on_exit!]

  describe "failed authentication" do
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

        assert {:ok, session_pid} =
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

        assert {:ok, session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert_eventually profile == HTTP.get_profile(session_id)
      end
    end
  end

  describe "successful authentication" do
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

    property "it fetches the now playing information" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        item = pick(Generators.playable_item())
        device = pick(Generators.device())

        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        player = expect_item_playing(credentials.token, item, device)

        assert {:ok, session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert player == HTTP.now_playing(session_id)
      end
    end

    property "it fetches devices information" do
      check all(
              credentials <- Generators.credentials(),
              session_id <- Generators.session_id(),
              profile <- Generators.profile(),
              max_runs: 5
            ) do
        device = pick(Generators.device())
        expect_profile(credentials.token, profile)
        expect_devices(credentials.token, [device])
        expect_nothing_playing(credentials.token)

        assert {:ok, session_pid} =
                 HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

        assert [device] == HTTP.get_devices(session_id)
      end
    end
  end

  describe "player functionality" do
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
        assert :ok == HTTP.set_volume(session_id, 100)
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

        timeouts =
          @default_timeouts
          |> Map.put(:inactivity, 300)

        assert {:ok, _session_pid} = HTTP.start_link(session_id, credentials, timeouts: timeouts)

        # Get initial devices

        assert [old_device] == HTTP.get_devices(session_id)

        # Change available devices and force a refresh

        expect_devices(credentials.token, [new_device])

        assert :ok == HTTP.refresh_devices(session_id)
        assert [new_device] == HTTP.get_devices(session_id)

        # Auto refresh cycle returns different devices

        expect_devices(credentials.token, [old_device])
        expect_nothing_playing(credentials.token)

        assert_eventually [old_device] == HTTP.get_devices(session_id)
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

  defp expect_transfer_playback(token, device_id) do
    Client.Mock
    |> expect(:transfer_playback, 1, fn ^token, ^device_id -> :ok end)
  end
end
