defmodule TuneWeb.PageLiveTest do
  use TuneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mox

  @avatar_url "http://example.com/user.png"
  @profile %{
    "display_name" => "Example user",
    "images" => [
      %{"url" => @avatar_url}
    ]
  }

  @song_title "Example song"
  @now_playing %{"item" => %{"name" => @song_title}}

  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    Tune.SpotifyMock
    |> expect(:get_profile, 2, fn "example-token" -> {:ok, @profile} end)
    |> expect(:now_playing, 2, fn "example-token" -> {:playing, @now_playing} end)

    {:ok, page_live, disconnected_html} =
      conn
      |> init_test_session(spotify_token: "example-token")
      |> live("/")

    assert disconnected_html =~ @song_title
    assert render(page_live) =~ @song_title
  end
end
