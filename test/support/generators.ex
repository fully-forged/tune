defmodule Tune.Generators do
  @moduledoc false
  import StreamData

  alias Tune.Spotify.Schema.{
    Album,
    Artist,
    Device,
    Episode,
    Playlist,
    Publisher,
    Show,
    Track,
    User
  }

  def search_type do
    one_of([
      constant(:track),
      constant(:album),
      constant(:artist),
      constant(:episode),
      constant(:show)
    ])
  end

  def searchable(:track), do: track()
  def searchable(:album), do: album()
  def searchable(:artist), do: artist()
  def searchable(:episode), do: episode()
  def searchable(:show), do: show()

  def search_query, do: string(:printable, max_length: 128)

  def item do
    one_of([album(), artist(), episode(), show(), track()])
  end

  def playable_item do
    one_of([track(), episode()])
  end

  def item_with_details do
    one_of([album(), artist(), show()])
  end

  def playlist do
    bind(name(), &playlist/1)
  end

  def playlist(name) do
    tuple(
      {id(), description(), thumbnails(), uniq_list_of(track(), min_length: 1, max_length: 32)}
    )
    |> bind(fn {id, description, thumbnails, tracks} ->
      constant(%Playlist{
        id: id,
        uri: "spotify:playlist:" <> id,
        name: name,
        description: description,
        thumbnails: thumbnails,
        tracks: tracks
      })
    end)
  end

  def track do
    tuple({id(), name(), duration(), artists(), track_number(), disc_number()})
    |> bind(fn {id, name, duration, artists, track_number, disc_number} ->
      bind(album(artists), fn album ->
        constant(%Track{
          id: id,
          uri: "spotify:track:" <> id,
          name: name,
          duration_ms: duration,
          track_number: track_number,
          disc_number: disc_number,
          album: album,
          artists: artists
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
        albums: :not_fetched,
        total_albums: :not_fetched,
        thumbnails: thumbnails
      })
    end)
  end

  def artists do
    uniq_list_of(artist(), min_length: 1, max_length: 8)
  end

  def album do
    bind(artists(), fn artists ->
      album(artists)
    end)
  end

  def album(artists) do
    bind(release_date_precision(), fn release_date_precision ->
      tuple(
        {id(), name(), thumbnails(), album_type(), album_group(),
         release_date(release_date_precision)}
      )
      |> bind(fn {id, name, thumbnails, album_type, album_group, release_date} ->
        constant(%Album{
          id: id,
          uri: "spotify:album:" <> id,
          name: name,
          album_type: album_type,
          album_group: album_group,
          artists: artists,
          thumbnails: thumbnails,
          release_date: release_date,
          release_date_precision: release_date_precision,
          tracks: :not_fetched
        })
      end)
    end)
  end

  def album_with_tracks do
    bind(release_date_precision(), fn release_date_precision ->
      tuple(
        {id(), name(), thumbnails(), album_type(), album_group(),
         release_date(release_date_precision), artists(),
         uniq_list_of(album_track(), min_length: 1, max_length: 32)}
      )
      |> bind(fn {id, name, thumbnails, album_type, album_group, release_date, artists, tracks} ->
        constant(%Album{
          id: id,
          uri: "spotify:album:" <> id,
          name: name,
          album_type: album_type,
          album_group: album_group,
          artists: artists,
          thumbnails: thumbnails,
          release_date: release_date,
          release_date_precision: release_date_precision,
          tracks: tracks
        })
      end)
    end)
  end

  def album_track do
    tuple({id(), name(), duration(), track_number(), disc_number()})
    |> bind(fn {id, name, duration, track_number, disc_number} ->
      constant(%Track{
        id: id,
        uri: "spotify:track:" <> id,
        name: name,
        duration_ms: duration,
        track_number: track_number,
        disc_number: disc_number,
        album: :not_fetched,
        artists: :not_fetched
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
        episodes: :not_fetched,
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

  def device do
    tuple({id(), boolean(), boolean(), boolean(), name(), device_type(), volume_percent()})
    |> bind(fn {id, is_active, is_private_session, is_restricted, name, type, volume_percent} ->
      constant(%Device{
        id: id,
        is_active: is_active,
        is_private_session: is_private_session,
        is_restricted: is_restricted,
        name: name,
        type: type,
        volume_percent: volume_percent
      })
    end)
  end

  def id, do: string(:alphanumeric, min_length: 6, max_length: 12)

  def name, do: string(:alphanumeric, min_length: 1, max_length: 128)

  def device_type, do: string(:alphanumeric, min_length: 1, max_length: 32)

  def description, do: string(:alphanumeric, min_length: 1, max_length: 128)

  def volume_percent do
    one_of([constant(nil), integer(1..99)])
  end

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

  # 90 minutes
  def duration, do: integer(500..:timer.minutes(90))

  def track_number, do: integer(1..100)

  def disc_number, do: integer(1..100)

  def release_date("year") do
    release_year()
  end

  def release_date("month") do
    tuple({release_year(), release_month()})
    |> bind(fn {release_year, release_month} ->
      constant("#{release_year}-#{release_month}")
    end)
  end

  def release_date("day") do
    tuple({release_year(), release_month(), release_day()})
    |> bind(fn {release_year, release_month, release_day} ->
      constant("#{release_year}-#{release_month}-#{release_day}")
    end)
  end

  defp release_date_precision do
    one_of([constant("year"), constant("month"), constant("day")])
  end

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
    one_of([premium_profile(), free_profile()])
  end

  def premium_profile do
    tuple({name(), image_url()})
    |> bind(fn {name, avatar_url} ->
      constant(%User{name: name, avatar_url: avatar_url, product: "premium"})
    end)
  end

  def free_profile do
    tuple({name(), image_url()})
    |> bind(fn {name, avatar_url} ->
      constant(%User{name: name, avatar_url: avatar_url, product: "free"})
    end)
  end

  def product do
    one_of([constant("premium")])
  end

  def album_type do
    one_of([constant("album"), constant("single"), constant("compilation")])
  end

  def album_group do
    one_of([
      constant("album"),
      constant("single"),
      constant("compilation"),
      constant("appears_on")
    ])
  end

  defp release_year do
    map(integer(1800..2020), &to_string/1)
  end

  defp release_month do
    map(integer(1..12), &to_string/1)
  end

  defp release_day do
    # to make things simpler, days are capped at 28 to avoid differentiating
    # between months
    map(integer(1..28), &to_string/1)
  end
end
