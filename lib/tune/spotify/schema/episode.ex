defmodule Tune.Spotify.Schema.Episode do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :description, :duration_ms, :show, :publisher, :thumbnails]
  defstruct [:id, :uri, :name, :description, :duration_ms, :show, :publisher, :thumbnails]
end
