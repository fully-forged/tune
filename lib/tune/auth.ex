defmodule Tune.Auth do
  alias Tune.Spotify.{Schema.User, Session}
  @type http_session :: map()

  @spec load_user(http_session()) :: {:authenticated, Session.id(), User.t()} | {:error, term()}
  def load_user(%{"spotify_id" => session_id, "spotify_credentials" => credentials}) do
    case spotify().setup(session_id, credentials) do
      :ok ->
        {:authenticated, session_id, spotify().get_profile(session_id)}

      error ->
        error
    end
  end

  def load_user(_session), do: {:error, :not_authenticated}

  defp spotify, do: Application.get_env(:tune, :spotify)
end
