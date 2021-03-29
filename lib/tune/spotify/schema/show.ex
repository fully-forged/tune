defmodule Tune.Spotify.Schema.Show do
  @moduledoc """
  Represents a show.
  """

  alias Tune.Spotify.Schema
  alias Schema.Publisher

  @enforce_keys [
    :id,
    :uri,
    :name,
    :spotify_url,
    :description,
    :episodes,
    :publisher,
    :thumbnails,
    :total_episodes
  ]
  defstruct [
    :id,
    :uri,
    :name,
    :spotify_url,
    :description,
    :episodes,
    :publisher,
    :thumbnails,
    :total_episodes
  ]

  @type id :: Schema.id()
  @type t :: %__MODULE__{
          id: id(),
          uri: Schema.uri(),
          name: String.t(),
          spotify_url: String.t(),
          description: String.t(),
          episodes: :not_fetched | [Schema.Episode.t()],
          publisher: Publisher.t(),
          thumbnails: Schema.thumbnails(),
          total_episodes: pos_integer()
        }
end
