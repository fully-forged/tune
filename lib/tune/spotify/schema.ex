defmodule Tune.Spotify.Schema do
  @moduledoc """
  Includes types and functions shared across schemas.
  """

  @type id :: String.t()
  @type uri :: String.t()
  @type thumbnail_size :: :small | :medium | :large
  @type thumbnails :: %{
          optional(thumbnail_size()) => String.t()
        }
end
