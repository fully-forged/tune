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

  def changes(%__MODULE__{status: status1}, %__MODULE__{status: status2})
      when status1 !== status2 do
    :status_changed
  end

  def changes(%__MODULE__{item: item1}, %__MODULE__{item: item2})
      when item1 !== item2 do
    :item_changed
  end

  def changes(%__MODULE__{progress_ms: progress_ms1}, %__MODULE__{progress_ms: progress_ms2})
      when progress_ms1 !== progress_ms2 do
    :progress_changed
  end

  def changes(_p1, _p2), do: :unchanged
end
