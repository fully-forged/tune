defmodule Tune.Spotify.Schema.Artist do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :thumbnails]
  defstruct [:id, :uri, :name, :thumbnails]
end
