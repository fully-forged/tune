defmodule Tune.Generators do
  @moduledoc false
  import StreamData

  alias Tune.Spotify.Schema.{Album, Artist, Episode, Publisher, Show, Track, User}

  def item do
    one_of([track(), episode()])
  end

  def track do
    tuple({id(), name(), duration(), artist()})
    |> bind(fn {id, name, duration, artist} ->
      bind(album(artist), fn album ->
        constant(%Track{
          id: id,
          uri: "spotify:track:" <> id,
          name: name,
          duration_ms: duration,
          album: album,
          artist: artist
        })
      end)
    end)
  end

  def artist do
    tuple({id(), name(), thumbnails()})
    |> bind(fn {id, name, thumbnails} ->
      constant(%Artist{
        id: id,
        uri: "spotify:artist:" <> id,
        name: name,
        thumbnails: thumbnails
      })
    end)
  end

  def album do
    bind(artist(), fn artist ->
      album(artist)
    end)
  end

  def album(artist) do
    tuple({id(), name(), thumbnails()})
    |> bind(fn {id, name, thumbnails} ->
      constant(%Album{
        id: id,
        uri: "spotify:album:" <> id,
        name: name,
        artist: artist,
        thumbnails: thumbnails
      })
    end)
  end

  def episode do
    tuple({id(), name(), description(), duration(), publisher(), thumbnails()})
    |> bind(fn {id, name, description, duration, publisher, thumbnails} ->
      bind(show(publisher), fn show ->
        constant(%Episode{
          id: id,
          uri: "spotify:episode:" <> id,
          name: name,
          description: description,
          duration_ms: duration,
          show: show,
          publisher: publisher,
          thumbnails: thumbnails
        })
      end)
    end)
  end

  def show do
    bind(publisher(), fn publisher ->
      show(publisher)
    end)
  end

  def show(publisher) do
    tuple({id(), name(), description(), thumbnails(), integer(1..20)})
    |> bind(fn {id, name, description, thumbnails, total_episodes} ->
      constant(%Show{
        id: id,
        uri: "spotify:show:" <> id,
        name: name,
        description: description,
        publisher: publisher,
        thumbnails: thumbnails,
        total_episodes: total_episodes
      })
    end)
  end

  def publisher do
    bind(name(), fn name ->
      constant(%Publisher{name: name})
    end)
  end

  def id, do: string(:alphanumeric, min_length: 6, max_length: 12)

  def name, do: string(:printable, min_length: 1, max_length: 128)

  def description, do: string(:printable, min_length: 1, max_length: 128)

  def thumbnails do
    map_of(
      one_of([constant(:small), constant(:medium), constant(:large)]),
      image_url(),
      max_tries: 100,
      max_length: 3
    )
  end

  def image_url do
    string(:printable, min_length: 16, max_length: 128)
  end

  def session_id, do: string(:alphanumeric, min_length: 6, max_length: 12)

  def token, do: string(:alphanumeric, min_length: 24, max_length: 32)

  # 45 minutes
  def duration, do: integer(500..2_700_000)

  def credentials do
    tuple({token(), token()})
    |> bind(fn {token, refresh_token} ->
      constant(%Ueberauth.Auth.Credentials{
        token: token,
        refresh_token: refresh_token
      })
    end)
  end

  def profile do
    tuple({name(), image_url()})
    |> bind(fn {name, avatar_url} ->
      constant(%User{name: name, avatar_url: avatar_url})
    end)
  end
end
