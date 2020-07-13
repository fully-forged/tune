defmodule TuneWeb.AuthController do
  use TuneWeb, :controller

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn
    |> put_flash(:info, "Hello #{auth.info.name}!")
    |> put_session(:spotify_credentials, auth.credentials)
    |> put_session(:spotify_id, auth.info.nickname)
    |> configure_session(renew: true)
    |> redirect(to: Routes.explorer_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, "Error authenticating via Spotify")
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :index))
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out")
    |> configure_session(drop: true)
    |> redirect(to: Routes.explorer_path(conn, :index))
  end
end
