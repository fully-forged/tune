defmodule Tune.Spotify.Session.HTTPTest do
  use ExUnit.Case
  use ExUnitProperties

  import Mox

  alias Tune.{Generators, Spotify.Schema, Spotify.Session.HTTP, Spotify.Client}
  alias Schema.Player

  @default_timeouts %{
    refresh: 50,
    retry: 50,
    inactivity: 50
  }

  setup [:set_mox_global, :verify_on_exit!]

  describe "initialization and authentication" do
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
      item = pick(Generators.item())
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

  defp expect_profile(token, profile) do
    Client.Mock
    |> expect(:get_profile, 1, fn ^token -> {:ok, profile} end)
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
end
