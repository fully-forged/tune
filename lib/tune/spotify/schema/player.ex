defmodule Tune.Spotify.Schema.Player do
  @moduledoc """
  Represents the status of a users playing device.
  """

  alias Tune.Spotify.Schema

  defstruct status: :not_playing,
            item: nil,
            progress_ms: 0

  @type t :: %__MODULE__{
          status: :not_playing | :paused | :playing,
          item: Schema.Track.t() | Schema.Episode.t(),
          progress_ms: pos_integer()
        }
end
