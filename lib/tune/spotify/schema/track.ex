defmodule Tune.Spotify.Schema.Track do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artist, :album]
  defstruct [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artist, :album]
end
