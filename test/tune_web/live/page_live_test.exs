defmodule TuneWeb.PageLiveTest do
  use TuneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    profile = %{
      "display_name" => "Example user",
      "images" => [
        %{"url" => "http://example.com/user.png"}
      ]
    }

    now_playing = %{"item" => %{"name" => "Example song"}}

    Tune.SpotifyMock
    |> expect(:get_profile, 2, fn "example-token" -> {:ok, profile} end)
    |> expect(:now_playing, 2, fn "example-token" -> {:playing, now_playing} end)

    {:ok, page_live, disconnected_html} =
      conn
      |> init_test_session(spotify_token: "example-token")
      |> live("/")

    assert disconnected_html =~ "Example user"
    assert disconnected_html =~ "Example song"
    assert render(page_live) =~ "Example user"
    assert render(page_live) =~ "Example song"
  end
end
