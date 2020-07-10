defmodule TuneWeb.LoggedOutTest do
  use TuneWeb.ConnCase

  import Phoenix.LiveViewTest

  test "/ displays a login notice", %{conn: conn} do
    {:ok, explorer_live, disconnected_html} = live(conn, "/")

    login_required_message = "The application requires you to Login into your Spotify account."

    assert disconnected_html =~ login_required_message
    assert render(explorer_live) =~ login_required_message
  end

  test "/ with search params displays a login notice", %{conn: conn} do
    {:ok, explorer_live, disconnected_html} = live(conn, "/?q=jethro+tull")

    login_required_message = "The application requires you to Login into your Spotify account."

    assert disconnected_html =~ login_required_message
    assert render(explorer_live) =~ login_required_message
  end
end
