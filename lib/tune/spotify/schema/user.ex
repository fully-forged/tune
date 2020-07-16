defmodule Tune.Spotify.Schema.User do
  @moduledoc false

  @enforce_keys [:name, :avatar_url]
  defstruct [:name, :avatar_url]
end
