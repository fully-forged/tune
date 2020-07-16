defmodule Tune.Spotify.Schema.Album do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :artist, :thumbnails, :tracks]
  defstruct [:id, :uri, :name, :artist, :thumbnails, :tracks]
end
