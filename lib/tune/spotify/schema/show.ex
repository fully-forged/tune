defmodule Tune.Spotify.Schema.Show do
  @moduledoc """
  Represents a show.
  """

  alias Tune.Spotify.Schema
  alias Schema.Publisher

  @enforce_keys [:id, :uri, :name, :description, :publisher, :thumbnails, :total_episodes]
  defstruct [:id, :uri, :name, :description, :publisher, :thumbnails, :total_episodes]

  @type t :: %__MODULE__{
          id: Schema.id(),
          uri: Schema.uri(),
          name: String.t(),
          description: String.t(),
          publisher: Publisher.t(),
          thumbnails: Schema.thumbnails(),
          total_episodes: pos_integer()
        }
end
