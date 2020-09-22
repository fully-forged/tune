defmodule TuneWeb.TrackView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Album, Artist, Player, Track}

  @spec playing?(Track.t(), Player.t()) :: boolean()
  defp playing?(%Track{id: track_id}, %Player{status: :playing, item: %{id: track_id}}),
    do: true

  defp playing?(_track, _now_playing), do: false

  @spec last_fm_link(Track.t(), Album.t(), Artist.t()) :: String.t()
  def last_fm_link(track, album, artist) do
    Path.join([
      "https://www.last.fm/music",
      URI.encode(artist.name),
      URI.encode(album.name),
      URI.encode(track.name)
    ])
  end

  @spec youtube_link(Track.t(), Artist.t()) :: String.t()
  def youtube_link(track, artist) do
    q = [search_query: artist.name <> " " <> track.name]
    "https://www.youtube.com/results?" <> URI.encode_query(q)
  end

  @spec musixmatch_link(Track.t(), Artist.t()) :: String.t()
  def musixmatch_link(track, artist) do
    Path.join([
      "https://www.musixmatch.com/lyrics",
      parameterize(artist.name),
      parameterize(track.name)
    ])
  end

  @unsafe_characters ~w(< > # % { } | \ ^ ~ [ ] ` ' ’ ")
  defp parameterize(s) do
    s
    |> String.replace(@unsafe_characters, "-")
    |> Slug.slugify(lowercase: false, separator: ?-)
  end
end
