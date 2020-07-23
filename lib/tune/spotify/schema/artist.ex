defmodule Tune.Spotify.Schema.Artist do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :albums, :thumbnails]
  defstruct [:id, :uri, :name, :albums, :thumbnails]
end
