defmodule Tune.DurationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tune.{Duration, Generators}

  @one_minute :timer.minutes(1)
  @one_minute_thirty_seconds :timer.seconds(90)
  @one_hour :timer.hours(1)

  describe "human duration" do
    property "it approximates to the nearest unit" do
      check all(duration <- Generators.duration()) do
        formatted = Duration.human(duration)

        case duration do
          d when d < @one_minute ->
            assert formatted == "Less than a minute"

          d when d < @one_minute_thirty_seconds ->
            assert formatted =~ "minute"
            refute formatted =~ "minutes"

          d when d < @one_hour ->
            assert formatted =~ "minutes"
            refute formatted =~ "hour"

          d when d in @one_hour..(@one_hour + @one_minute) ->
            refute formatted =~ "minute"
            assert formatted =~ "hour"

          _ ->
            assert formatted =~ "minute"
            assert formatted =~ "hour"
        end
      end
    end
  end
end
