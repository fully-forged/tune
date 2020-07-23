defmodule Tune.Spotify.Schema.Track do
  @moduledoc """
  Represents an album track.
  """

  alias Tune.Spotify.Schema
  alias Schema.{Album, Artist}

  @enforce_keys [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artist, :album]
  defstruct [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artist, :album]

  @type t :: %__MODULE__{
          id: Schema.id(),
          uri: Schema.uri(),
          name: String.t(),
          duration_ms: pos_integer(),
          track_number: pos_integer(),
          track_number: pos_integer(),
          artist: Artist.t(),
          album: Album.t()
        }
end
