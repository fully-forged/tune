defmodule Tune.Spotify.Schema.Episode do
  @moduledoc """
  Represents an episode.

  Depending on how the episode is retrieved, it may or may not include a show and a publisher.
  """

  alias Tune.Spotify.Schema
  alias Schema.{Publisher, Show}

  @enforce_keys [:id, :uri, :name, :description, :duration_ms, :show, :publisher, :thumbnails]
  defstruct [:id, :uri, :name, :description, :duration_ms, :show, :publisher, :thumbnails]

  @type t :: %__MODULE__{
          id: Schema.id(),
          uri: Schema.uri(),
          name: String.t(),
          description: String.t(),
          duration_ms: pos_integer(),
          show: Show.t() | :not_fetched,
          publisher: Publisher.t() | :not_fetched,
          thumbnails: Schema.thumbnails()
        }
end
