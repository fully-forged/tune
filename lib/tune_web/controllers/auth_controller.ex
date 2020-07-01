defmodule TuneWeb.AuthController do
  use TuneWeb, :controller

  plug Ueberauth

  def callback(conn = %{assigns: %{ueberauth_auth: auth}}, _params) do
    conn
    |> put_flash(:info, "Hello #{auth.info.name}!")
    |> configure_session(renew: true)
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def callback(conn = %{assigns: %{ueberauth_failure: _failure}}, _params) do
    conn
    |> put_flash(:error, "Error authenticating via Spotify")
    |> configure_session(drop: true)
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
