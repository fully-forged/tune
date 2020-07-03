defmodule Tune.Spotify do
  @type session_id :: String.t()
  @type credentials :: Ueberauth.Auth.Credentials.t()

  @callback setup(session_id(), credentials()) :: :ok | {:error, term()}
  @callback subscribe(session_id()) :: :ok | {:error, term()}
  @callback get_profile(session_id()) :: {:ok, %Tune.User{}} | {:error, term()}
  @callback now_playing(session_id()) ::
              :not_playing | {:playing, %Tune.Track{} | %Tune.Episode{}} | {:error, term()}
end
