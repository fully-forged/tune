defmodule Tune.Duration do
  @moduledoc """
  Provides functions to convert millisecond durations to different formats.
  """

  @minute :timer.minutes(1)
  @hour :timer.hours(1)

  import Tune.Gettext

  @type milliseconds :: pos_integer()

  @doc """
  Given a duration in milliseconds, returns a string with the duration formatted
  as hours, minutes and seconds, omitting units where appropriate.

      iex> milliseconds = :timer.seconds(5)
      iex> Tune.Duration.hms(milliseconds)
      "0:05"
      iex> milliseconds = :timer.seconds(61)
      iex> Tune.Duration.hms(milliseconds)
      "1:01"
      iex> milliseconds = :timer.hours(2)
      iex> Tune.Duration.hms(milliseconds)
      "2:00:00"
  """
  def hms(milliseconds) do
    milliseconds
    |> System.convert_time_unit(:millisecond, :second)
    |> format_seconds()
  end

  @doc """
  Given a duration in milliseconds, returns a localized, human-readable
  representation of that duration.

      iex> Tune.Duration.human(100)
      "Less than a minute"

  Durations are rounded to the minute:

      iex> milliseconds = :timer.seconds(61)
      iex> Tune.Duration.human(milliseconds)
      "1 minute"
      iex> milliseconds = :timer.seconds(95)
      iex> Tune.Duration.human(milliseconds)
      "2 minutes"
  """
  @spec human(milliseconds()) :: String.t()
  def human(milliseconds) when milliseconds < @minute do
    gettext("Less than a minute")
  end

  def human(milliseconds) when milliseconds < @hour do
    total_seconds = milliseconds_to_rounded_seconds(milliseconds)
    total_minutes = seconds_to_rounded_minutes(total_seconds)

    ngettext(
      "1 minute",
      "%{count} minutes",
      total_minutes
    )
  end

  def human(milliseconds) when milliseconds >= @hour do
    total_seconds = milliseconds_to_rounded_seconds(milliseconds)
    total_minutes = seconds_to_rounded_minutes(total_seconds)
    total_hours = div(total_minutes, 60)
    remaining_minutes = rem(total_minutes, 60)

    if remaining_minutes > 0 do
      hours_fragment = ngettext("1 hour", "%{count} hours", total_hours)
      minutes_fragment = ngettext("1 minute", "%{count} minutes", remaining_minutes)

      gettext("%{hours} and %{minutes}", %{hours: hours_fragment, minutes: minutes_fragment})
    else
      ngettext("1 hour", "%{count} hours", total_hours)
    end
  end

  defp milliseconds_to_rounded_seconds(milliseconds) do
    total_seconds = System.convert_time_unit(milliseconds, :millisecond, :second)
    remaining_milliseconds = rem(milliseconds, 1000)

    if remaining_milliseconds > 500 do
      total_seconds + 1
    else
      total_seconds
    end
  end

  defp seconds_to_rounded_minutes(seconds) do
    total_minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    if remaining_seconds > 30 do
      total_minutes + 1
    else
      total_minutes
    end
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
    "#{minutes}:#{zero_pad(seconds)}"
  end

  defp format_minutes(minutes, seconds) do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)

    format_hours(hours, remaining_minutes, seconds)
  end

  defp format_hours(hours, minutes, seconds) do
    "#{hours}:#{zero_pad(minutes)}:#{zero_pad(seconds)}"
  end

  defp zero_pad(integer) do
    integer
    |> to_string()
    |> String.pad_leading(2, "0")
  end
end
