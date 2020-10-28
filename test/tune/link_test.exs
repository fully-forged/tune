defmodule Tune.LinkTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tune.{Link, Generators, Spotify.Schema.Album}

  describe "youtube" do
    property "it generates well-formed links" do
      check all(track <- Generators.track()) do
        main_artist = Album.main_artist(track.album)

        album_uri =
          track.album
          |> Link.youtube()
          |> URI.parse()

        assert album_uri.scheme == "https"
        assert album_uri.authority == "www.youtube.com"
        assert album_uri.host == "www.youtube.com"
        assert album_uri.path == "/results"
        assert album_uri.query =~ "search_query="
        assert album_uri.query =~ URI.encode(track.album.name)
        assert album_uri.query =~ URI.encode(main_artist.name)

        artist_uri =
          main_artist
          |> Link.youtube()
          |> URI.parse()

        assert artist_uri.scheme == "https"
        assert artist_uri.authority == "www.youtube.com"
        assert artist_uri.host == "www.youtube.com"
        assert artist_uri.path == "/results"
        assert artist_uri.query =~ "search_query="
        assert artist_uri.query =~ URI.encode(main_artist.name)

        track_uri =
          track
          |> Link.youtube(main_artist)
          |> URI.parse()

        assert track_uri.scheme == "https"
        assert track_uri.authority == "www.youtube.com"
        assert track_uri.host == "www.youtube.com"
        assert track_uri.path == "/results"
        assert track_uri.query =~ "search_query="
        assert track_uri.query =~ URI.encode(main_artist.name)
        assert track_uri.query =~ URI.encode(track.name)
      end
    end
  end

  describe "last.fm" do
    property "it generates well-formed links" do
      check all(track <- Generators.track()) do
        main_artist = Album.main_artist(track.album)

        album_uri =
          track.album
          |> Link.last_fm()
          |> URI.parse()

        assert album_uri.scheme == "https"
        assert album_uri.authority == "www.last.fm"
        assert album_uri.host == "www.last.fm"

        assert album_uri.path ==
                 "/music/#{URI.encode(main_artist.name)}/#{URI.encode(track.album.name)}"

        artist_uri =
          main_artist
          |> Link.last_fm()
          |> URI.parse()

        assert artist_uri.scheme == "https"
        assert artist_uri.authority == "www.last.fm"
        assert artist_uri.host == "www.last.fm"

        assert artist_uri.path ==
                 "/music/#{URI.encode(main_artist.name)}"

        track_uri =
          track
          |> Link.last_fm(track.album, main_artist)
          |> URI.parse()

        assert track_uri.scheme == "https"
        assert track_uri.authority == "www.last.fm"
        assert track_uri.host == "www.last.fm"

        assert track_uri.path ==
                 "/music/#{URI.encode(main_artist.name)}/#{URI.encode(track.album.name)}/#{
                   URI.encode(track.name)
                 }"
      end
    end
  end

  describe "wikipedia" do
    property "it generates well-formed links" do
      check all(artist <- Generators.artist()) do
        artist_uri =
          artist
          |> Link.wikipedia()
          |> URI.parse()

        assert artist_uri.scheme == "https"
        assert artist_uri.authority == "en.wikipedia.org"
        assert artist_uri.host == "en.wikipedia.org"

        assert artist_uri.path ==
                 "/wiki/#{URI.encode(artist.name)}_(band)"
      end
    end
  end

  describe "musixmatch" do
    property "it generates well-formed links" do
      check all(track <- Generators.track()) do
        main_artist = Album.main_artist(track.album)

        track_uri =
          track
          |> Link.musixmatch(main_artist)
          |> URI.parse()

        assert track_uri.scheme == "https"
        assert track_uri.authority == "www.musixmatch.com"
        assert track_uri.host == "www.musixmatch.com"

        assert track_uri.path =~ "/lyrics/"
        unsafe_characters = ~w(< > # % \( \) { } | \ ^ ~ [ ] ` ' ’ ")

        for unsafe_character <- unsafe_characters do
          refute String.contains?(track_uri.path, unsafe_character)
        end
      end
    end

    test "edge cases" do
      track = pick(Generators.track())
      main_artist = Album.main_artist(track.album)

      track = %{track | name: "(-)"}

      assert is_binary(Link.musixmatch(track, main_artist))
    end
  end
end
