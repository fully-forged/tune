defmodule Tune.Spotify.Schema.Track do
  @moduledoc """
  Represents an album track.
  """

  alias Tune.{Duration, Spotify.Schema}
  alias Schema.{Album, Artist}

  @enforce_keys [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artists, :album]
  defstruct [:id, :uri, :name, :duration_ms, :track_number, :disc_number, :artists, :album]

  @type t :: %__MODULE__{
          id: Schema.id(),
          uri: Schema.uri(),
          name: String.t(),
          duration_ms: Duration.milliseconds(),
          track_number: pos_integer(),
          disc_number: pos_integer(),
          artists: [Artist.t()],
          album: Album.t()
        }

  @spec artist_ids([t()]) :: [Schema.id()]
  def artist_ids(tracks) do
    tracks
    |> Enum.flat_map(fn t ->
      Enum.map(t.artists, & &1.id)
    end)
    |> Enum.uniq()
  end
end
