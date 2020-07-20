defmodule Tune.Spotify.Schema.Album do
  @moduledoc false

  @enforce_keys [
    :id,
    :uri,
    :name,
    :artist,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]
  defstruct [
    :id,
    :uri,
    :name,
    :artist,
    :release_date,
    :release_date_precision,
    :thumbnails,
    :tracks
  ]
end
