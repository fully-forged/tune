defmodule Tune.Duration do
  @moduledoc false

  @minute :timer.minutes(1)
  @hour :timer.hours(1)

  import Tune.Gettext

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
    total_seconds = div(milliseconds, 1000)
    remaining_milliseconds = rem(milliseconds, 1000)

    if remaining_milliseconds >= 500 do
      total_seconds + 1
    else
      total_seconds
    end
  end

  defp seconds_to_rounded_minutes(seconds) do
    total_minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    if remaining_seconds >= 30 do
      total_minutes + 1
    else
      total_minutes
    end
  end
end
