defmodule Tune.Spotify.Schema.Track do
  @moduledoc false
  defstruct [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artist, :album]
end
