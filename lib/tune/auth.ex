defmodule Tune.Auth do
  @moduledoc """
  Includes functions used to perform authentication.
  """

  alias Tune.Spotify.{Schema.User, Session}
  @type http_session :: map()

  @spec load_user(http_session()) :: {:authenticated, Session.id(), User.t()} | {:error, term()}
  def load_user(%{"spotify_id" => session_id, "spotify_credentials" => credentials}) do
    case spotify_session().setup(session_id, credentials) do
      :ok ->
        {:authenticated, session_id, spotify_session().get_profile(session_id)}

      error ->
        error
    end
  end

  def load_user(_session), do: {:error, :not_authenticated}

  defp spotify_session, do: Application.get_env(:tune, :spotify_session)
end
