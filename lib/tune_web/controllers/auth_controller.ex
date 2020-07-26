defmodule TuneWeb.AuthController do
  @moduledoc """
  Controls authentication via the Spotify API.
  """
  use TuneWeb, :controller

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn
    |> put_flash(:info, "Hello #{auth.info.name}!")
    |> put_session(:spotify_credentials, auth.credentials)
    |> put_session(:spotify_id, auth.info.nickname)
    |> configure_session(renew: true)
    |> redirect(to: Routes.explorer_path(conn, :search))
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, gettext("Error authenticating via Spotify"))
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :search))
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out"))
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :search))
  end

  def ensure_authenticated(conn, _opts) do
    session = get_session(conn)

    case Tune.Auth.load_user(session) do
      {:authenticated, session_id, user} ->
        conn
        |> assign(:status, :authenticated)
        |> assign(:user, user)
        |> assign(:session_id, session_id)

      {:error, :not_authenticated} ->
        conn
        |> assign(:status, :not_authenticated)
        |> Phoenix.Controller.redirect(to: Routes.auth_path(conn, :new))
        |> halt()
    end
  end
end
