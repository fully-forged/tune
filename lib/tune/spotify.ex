defmodule Tune.Spotify do
  @type token :: String.t()

  @callback get_profile(token()) :: {:ok, map()} | {:error, term()}
  @callback now_playing(token()) :: :not_playing | {:playing, %Tune.Track{}} | {:error, term()}
end
