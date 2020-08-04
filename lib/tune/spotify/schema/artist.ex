defmodule Tune.Spotify.Schema.Artist do
  @moduledoc """
  Represents an artist.

  Depending on how the artist is retrieved, it may or may not include albums.
  """

  alias Tune.Spotify.Schema
  alias Schema.Album

  @enforce_keys [:id, :uri, :name, :albums, :thumbnails]
  defstruct [:id, :uri, :name, :albums, :thumbnails]

  @type id :: Schema.id()

  @type t :: %__MODULE__{
          id: id(),
          uri: Schema.uri(),
          name: String.t(),
          albums: [Album.t()] | :not_fetched,
          thumbnails: Schema.thumbnails()
        }
end
