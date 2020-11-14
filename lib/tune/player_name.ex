defmodule Tune.PlayerName do
  @moduledoc """
  This module contains logic to generate player names
  with a reasonable degree of entropy without the need of a stateful generator.

  Player names are supposed to be unique for a given user/session. A user is
  likely to have < 10 clients open at any given time.

  To guarantee a unique player name, we start with a list of 250+ musical
  instruments. At generation time, we pick one random instrument and
  append a value derived from current time, rounded to the second.

  Names are taken from a text list stored in priv/name_generator/instruments.txt,
  copied from https://simple.wikipedia.org/wiki/List_of_musical_instruments.
  """

  instruments_file =
    :code.priv_dir(:tune)
    |> Path.join("name_generator")
    |> Path.join("instruments.txt")

  @external_resource instruments_file

  @instruments instruments_file
               |> File.stream!()
               |> Stream.map(&String.trim/1)
               |> Stream.map(&Slug.slugify/1)
               |> Enum.to_list()

  @doc """
  Pick an instrument at random and return it in slug form.
  """
  @spec random_slug :: String.t()
  def random_slug do
    instrument =
      @instruments
      |> Enum.shuffle()
      |> hd()

    {suffix, _} =
      Time.utc_now()
      |> Time.to_seconds_after_midnight()

    "#{instrument}-#{suffix}"
  end
end
