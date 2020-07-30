defmodule Tune.Spotify.Schema.Device do
  @moduledoc """
  Represents a device able to play.
  """

  alias Tune.Spotify.Schema

  @enforce_keys [
    :id,
    :is_active,
    :is_private_session,
    :is_restricted,
    :name,
    :type,
    :volume_percent
  ]
  defstruct [
    :id,
    :is_active,
    :is_private_session,
    :is_restricted,
    :name,
    :type,
    :volume_percent
  ]

  @type t :: %__MODULE__{
          id: Schema.id(),
          is_active: boolean(),
          is_private_session: boolean(),
          is_restricted: boolean(),
          name: String.t(),
          type: String.t(),
          volume_percent: nil | 0..100
        }
end
