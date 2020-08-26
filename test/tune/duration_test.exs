defmodule Tune.DurationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tune.{Duration, Generators}

  doctest Duration

  @thirty_seconds :timer.seconds(30)
  @thirty_seconds_and_a_half :timer.seconds(30) + 500
  @one_minute :timer.minutes(1)
  @one_hour :timer.hours(1)

  describe "human duration" do
    property "it approximates to the nearest unit" do
      check all(duration <- Generators.duration()) do
        formatted = Duration.human(duration)

        case duration do
          d when d < @one_minute ->
            assert formatted == "Less than a minute"

          d when d <= @one_minute + @thirty_seconds ->
            assert formatted =~ "minute"
            refute formatted =~ "minutes"

          d when d < @one_hour ->
            assert formatted =~ "minutes"
            refute formatted =~ "hour"

          d when d in @one_hour..(@one_hour + @thirty_seconds_and_a_half) ->
            refute formatted =~ "minute"
            assert formatted =~ "hour"

          _ ->
            assert formatted =~ "minute"
            assert formatted =~ "hour"
        end
      end
    end
  end

  describe "hms" do
    property "it includes only meaningful units" do
      check all(duration <- Generators.duration()) do
        hms = Duration.hms(duration)

        case duration do
          d when d < @one_minute ->
            assert ["0", seconds_string] = String.split(hms, ":")
            assert {seconds, ""} = Integer.parse(seconds_string)
            assert seconds in 0..59

          d when d in @one_minute..@one_hour ->
            assert [minutes_string, seconds_string] = String.split(hms, ":")
            assert {minutes, ""} = Integer.parse(minutes_string)
            assert minutes in 0..59
            assert {seconds, ""} = Integer.parse(seconds_string)
            assert seconds in 0..59

          d when d >= @one_hour ->
            assert [hours_string, minutes_string, seconds_string] = String.split(hms, ":")
            assert {minutes, ""} = Integer.parse(minutes_string)
            assert minutes in 0..59
            assert {seconds, ""} = Integer.parse(seconds_string)
            assert seconds in 0..59
            assert {hours, ""} = Integer.parse(hours_string)
            assert hours >= 1
        end
      end
    end
  end
end
