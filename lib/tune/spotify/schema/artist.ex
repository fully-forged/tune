defmodule Tune.Spotify.Schema.Artist do
  @moduledoc """
  Represents an artist.

  Depending on how the artist is retrieved, it may or may not include albums.
  """

  alias Tune.Spotify.Schema
  alias Schema.Album

  @enforce_keys [:id, :uri, :name, :spotify_url, :albums, :total_albums, :genres, :thumbnails]
  defstruct [:id, :uri, :name, :spotify_url, :albums, :total_albums, :genres, :thumbnails]

  @type id :: Schema.id()
  @type t :: %__MODULE__{
          id: id(),
          uri: Schema.uri(),
          name: String.t(),
          spotify_url: String.t(),
          albums: [Album.t()] | :not_fetched,
          total_albums: pos_integer() | :not_fetched,
          genres: [String.t()],
          thumbnails: Schema.thumbnails()
        }
end
