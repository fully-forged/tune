defmodule Tune.Spotify.Schema.Track do
  @moduledoc false
  defstruct [:id, :uri, :name, :duration_ms, :artist, :album]
end
