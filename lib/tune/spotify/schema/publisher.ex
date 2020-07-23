defmodule Tune.Spotify.Schema.Publisher do
  @moduledoc """
  Represents a show/episode publisher.
  """

  @enforce_keys [:name]
  defstruct [:name]

  @type t :: %__MODULE__{name: String.t()}
end
