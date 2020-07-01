defmodule TuneWeb.PageLiveTest do
  use TuneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    Tune.SpotifyMock
    |> expect(:get_profile, 2, fn "example-token" ->
      {:ok, %{"display_name" => "Example user"}}
    end)
    |> expect(:now_playing, 2, fn "example-token" ->
      {:playing, %{"item" => %{"name" => "Example song"}}}
    end)

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
