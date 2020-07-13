defmodule Tune.Spotify.Schema.Episode do
  @moduledoc false
  defstruct [:id, :uri, :name, :description, :duration_ms, :show, :publisher, :thumbnails]
end
