defmodule Tune.Spotify.Schema.Player do
  alias Tune.Spotify.Schema

  defstruct status: :not_playing,
            item: nil,
            progress_ms: 0

  @type t :: %__MODULE__{
          status: :not_playing | :paused | :playing,
          item: %Schema.Track{} | %Schema.Episode{},
          progress_ms: pos_integer()
        }
end
