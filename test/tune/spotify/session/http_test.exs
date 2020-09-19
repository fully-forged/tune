defmodule Tune.Spotify.Session.HTTPTest do
  use ExUnit.Case
  use ExUnitProperties

  import Mox
  import Eventually

  alias Tune.{Generators, Spotify.Schema, Spotify.Session.HTTP, Spotify.Client}
  alias Schema.{Episode, Player, Track}

  @default_timeouts %{
    refresh: 100,
    retry: 100,
    inactivity: 100
  }

  setup [:set_mox_global, :verify_on_exit!]

  describe "failed authentication" do
    @tag capture_log: true
    test "with an expired token, the process stops" do
      credentials = pick(Generators.credentials())
      session_id = pick(Generators.session_id())

      token = credentials.token

      Client.Mock
      |> expect(:get_profile, 1, fn ^token -> {:error, :invalid_token} end)

      Process.flag(:trap_exit, true)

      assert {:ok, session_pid} =
               HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

      assert_receive {:EXIT, ^session_pid, :invalid_token}
    end

    test "with an expired token, the process refreshes the token and retries" do
      old_credentials = pick(Generators.credentials())
      new_credentials = pick(Generators.credentials())
      session_id = pick(Generators.session_id())
      profile = pick(Generators.profile())

      expect_profile_with_token_refresh(old_credentials, new_credentials)
      expect_profile(new_credentials.token, profile)
      expect_nothing_playing(new_credentials.token)
      expect_no_devices(new_credentials.token)

      assert {:ok, session_pid} =
               HTTP.start_link(session_id, old_credentials, timeouts: @default_timeouts)

      assert profile == HTTP.get_profile(session_id)
    end

    test "with a transient network error, the process retries" do
      credentials = pick(Generators.credentials())
      session_id = pick(Generators.session_id())
      profile = pick(Generators.profile())

      expect_profile_with_network_error(credentials.token)
      expect_profile(credentials.token, profile)
      expect_nothing_playing(credentials.token)
      expect_no_devices(credentials.token)

      assert {:ok, session_pid} =
               HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

      assert_eventually profile == HTTP.get_profile(session_id)
    end
  end

  describe "successful authentication" do
    setup do
      [
        credentials: pick(Generators.credentials()),
        session_id: pick(Generators.session_id()),
        profile: pick(Generators.profile())
      ]
    end

    test "it fetches the user profile", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      expect_profile(credentials.token, profile)
      expect_nothing_playing(credentials.token)
      expect_no_devices(credentials.token)

      assert {:ok, _session_pid} =
               HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

      assert profile == HTTP.get_profile(session_id)
    end

    test "it fetches the now playing information", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      device = pick(Generators.device())

      expect_profile(credentials.token, profile)
      expect_devices(credentials.token, [device])
      player = expect_item_playing(credentials.token, item, device)

      assert {:ok, session_pid} =
               HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

      assert player == HTTP.now_playing(session_id)
    end

    test "it fetches devices information", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      device = pick(Generators.device())
      expect_profile(credentials.token, profile)
      expect_devices(credentials.token, [device])
      expect_nothing_playing(credentials.token)

      assert {:ok, session_pid} =
               HTTP.start_link(session_id, credentials, timeouts: @default_timeouts)

      assert [device] == HTTP.get_devices(session_id)
    end
  end

  describe "player functionality" do
    setup do
      [
        credentials: pick(Generators.credentials()),
        session_id: pick(Generators.session_id()),
        profile: pick(Generators.profile())
      ]
    end

    test "toggling play when paused", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "toggling play when playing", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "play an item", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      old_item = pick(Generators.playable_item())
      new_item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "play an item with context", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      old_item = pick(Generators.playable_item())
      new_item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "next/prev", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      next_item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "set volume", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      device = pick(Generators.device())

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

    test "transfer playback", %{
      credentials: credentials,
      session_id: session_id,
      profile: profile
    } do
      item = pick(Generators.playable_item())
      old_device = pick(Generators.device())
      new_device = pick(Generators.device())

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
