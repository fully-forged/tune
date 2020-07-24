defmodule Tune.Spotify.Schema do
  @moduledoc """
  Includes types and functions shared across schemas.
  """

  @type id :: String.t()
  @type uri :: String.t()
  @type thumbnails :: %{
          optional(:small | :medium | :large) => String.t()
        }
end
