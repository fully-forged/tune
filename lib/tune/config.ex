defmodule Tune.Config do
  @moduledoc """
  This module is responsible for all runtime config resolution.
  """

  use Vapor.Planner

  dotenv()

  config :web,
         env([
           {:port, "PORT", map: &String.to_integer/1, required: false},
           {:secret_key_base, "SECRET_KEY_BASE"},
           {:session_encryption_salt, "SESSION_ENCRYPTION_SALT"},
           {:admin_user, "ADMIN_USER"},
           {:admin_password, "ADMIN_PASSWORD"}
         ])

  config :spotify,
         env(
           spotify_client_id: "SPOTIFY_CLIENT_ID",
           spotify_client_secret: "SPOTIFY_CLIENT_SECRET"
         )
end
