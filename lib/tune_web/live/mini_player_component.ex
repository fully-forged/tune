defmodule TuneWeb.MiniPlayerComponent do
  @moduledoc false
  use TuneWeb, :live_component

  alias TuneWeb.{PlayerView, ProgressBarComponent}

  @default_small_thumbnail "https://via.placeholder.com/48"

  alias Tune.Spotify.Schema.{Episode, Track}

  @spec thumbnail(Track.t() | Episode.t()) :: String.t()
  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :small, @default_small_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :small, @default_small_thumbnail)

  @spec name(Track.t() | Episode.t()) :: String.t()
  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name

  defp devices_options([], _player_id), do: nil

  defp devices_options(devices, player_name) do
    active_device_id =
      case Enum.find(devices, fn d -> d.is_active end) do
        nil -> nil
        active_device -> active_device.id
      end

    devices
    |> Enum.map(fn d ->
      if d.name == player_name do
        {d.name <> " (" <> gettext("this device") <> ")", d.id}
      else
        {d.name, d.id}
      end
    end)
    |> options_for_select(active_device_id)
  end
end
