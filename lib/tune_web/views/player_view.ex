defmodule TuneWeb.PlayerView do
  use TuneWeb, :view

  @default_small_thumbnail "https://via.placeholder.com/48"

  alias Tune.Spotify.Schema.{Episode, Track}

  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :small, @default_small_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :small, @default_small_thumbnail)

  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name

  defp author_name(%Track{artist: artist}), do: artist.name
  defp author_name(%Episode{publisher: publisher}), do: publisher.name

  defp format_duration(ms) do
    ms
    |> System.convert_time_unit(:millisecond, :second)
    |> format_seconds()
  end

  defp format_seconds(seconds) when seconds <= 59 do
    "0:#{zero_pad(seconds)}"
  end

  defp format_seconds(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    format_minutes(minutes, remaining_seconds)
  end

  defp format_minutes(minutes, seconds) when minutes <= 59 do
    "#{zero_pad(minutes)}:#{zero_pad(seconds)}"
  end

  defp format_minutes(minutes, seconds) do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)

    format_hours(hours, remaining_minutes, seconds)
  end

  defp format_hours(hours, minutes, seconds) do
    "#{zero_pad(hours)}:#{zero_pad(minutes)}:#{zero_pad(seconds)}"
  end

  defp zero_pad(integer) do
    integer
    |> to_string()
    |> String.pad_leading(2, "0")
  end
end
