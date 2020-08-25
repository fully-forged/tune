defmodule TuneWeb.AuthController do
  @moduledoc """
  Controls authentication via the Spotify API.
  """
  use TuneWeb, :controller

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    premium? = get_in(auth.extra.raw_info, [:user, "product"]) == "premium"

    conn =
      if premium? do
        put_flash(conn, :info, "Hello #{auth.info.name}!")
      else
        put_flash(conn, :warning, """
        Hello #{auth.info.name}!
        As you don't have a premium account, the embedded audio player and all audio controls are disabled.
        """)
      end

    conn
    |> put_session(:spotify_credentials, auth.credentials)
    |> put_session(:spotify_id, auth.info.nickname)
    |> configure_session(renew: true)
    |> redirect(to: Routes.explorer_path(conn, :suggestions))
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, gettext("Error authenticating via Spotify"))
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :suggestions))
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out"))
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :suggestions))
  end

  def ensure_authenticated(conn, _opts) do
    session = get_session(conn)

    case Tune.Auth.load_user(session) do
      {:authenticated, session_id, user} ->
        conn
        |> assign(:status, :authenticated)
        |> assign(:user, user)
        |> assign(:release_radar_playlist_id, get_release_radar_playlist_id())
        |> assign(:session_id, session_id)

      {:error, :not_authenticated} ->
        conn
        |> assign(:status, :not_authenticated)
        |> Phoenix.Controller.redirect(to: Routes.auth_path(conn, :new))
        |> halt()
    end
  end

  defp get_release_radar_playlist_id do
    Tune.Config
    |> Vapor.load!()
    |> get_in([:spotify, :release_radar_playlist_id])
  end
end
