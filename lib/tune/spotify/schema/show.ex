defmodule Tune.Spotify.Schema.Show do
  @moduledoc false

  @enforce_keys [:id, :uri, :name, :description, :publisher, :thumbnails, :total_episodes]
  defstruct [:id, :uri, :name, :description, :publisher, :thumbnails, :total_episodes]
end
