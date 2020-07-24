defmodule Tune.Spotify.Schema.User do
  @moduledoc """
  Represents a Spotify user.
  """

  @enforce_keys [:name, :avatar_url]
  defstruct [:name, :avatar_url]

  @type t :: %__MODULE__{
          name: String.t(),
          avatar_url: String.t()
        }
end
