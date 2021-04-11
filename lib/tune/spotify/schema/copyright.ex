defmodule Tune.Spotify.Schema.Copyright do
  @moduledoc """
  Represents copyright information for a given object.
  """

  @enforce_keys [:text, :type]
  defstruct [:text, :type]

  @type t :: %__MODULE__{text: String.t(), type: String.t()}
end
