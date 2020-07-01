defmodule Tune.Spotify do
  @type token :: String.t()

  @callback get_profile(token()) :: {:ok, map()} | {:error, term()}
end
