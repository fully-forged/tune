defmodule Tune.DurationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tune.{Duration, Generators}

  @minute :timer.minutes(1)
  @hour :timer.hours(1)

  describe "human duration" do
    property "it approximates to the nearest unit" do
      check all(duration <- Generators.duration()) do
        formatted = Duration.human(duration)

        case duration do
          d when d < @minute ->
            assert formatted == "Less than a minute"

          d when d < @hour ->
            assert formatted =~ "minute(s)"
            refute formatted =~ "hour(s)"

          d when d >= @hour ->
            assert formatted =~ "minute(s)"
            assert formatted =~ "hour(s)"
        end
      end
    end
  end
end
