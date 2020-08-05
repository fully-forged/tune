defmodule TuneWeb.EpisodeView do
  @moduledoc false
  use TuneWeb, :view

  alias Tune.Spotify.Schema.{Episode, Player}

  @spec playing?(Episode.t(), Player.t()) :: boolean()
  defp playing?(%Episode{id: episode_id}, %Player{status: :playing, item: %{id: episode_id}}),
    do: true

  defp playing?(_episode, _now_playing), do: false
end
