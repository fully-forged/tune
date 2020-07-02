defmodule Tune.Spotify do
  @type token :: String.t()

  @callback setup(token()) :: :ok | {:error, term()}
  @callback subscribe(token()) :: :ok | {:error, term()}
  @callback get_profile(token()) :: {:ok, %Tune.User{}} | {:error, term()}
  @callback now_playing(token()) :: :not_playing | {:playing, %Tune.Track{}} | {:error, term()}
end
