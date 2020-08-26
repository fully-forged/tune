defmodule Tune.Spotify.Schema.Player do
  @moduledoc """
  Represents the status of a users playing device.
  """

  alias Tune.{Duration, Spotify.Schema}

  defstruct status: :not_playing,
            item: nil,
            progress_ms: 0,
            device: nil

  @type t :: %__MODULE__{
          status: :not_playing | :paused | :playing,
          item: Schema.Track.t() | Schema.Episode.t(),
          progress_ms: Duration.milliseconds(),
          device: Schema.Device.t()
        }
  @type prop :: :status | :item | :progress_ms | :device

  @spec changes(t(), t()) :: [prop()]
  def changes(p1, p2) do
    Enum.reduce([:status, :item, :progress_ms, :device], [], fn prop, acc ->
      if Map.get(p1, prop) !== Map.get(p2, prop) do
        [prop | acc]
      else
        acc
      end
    end)
  end
end
