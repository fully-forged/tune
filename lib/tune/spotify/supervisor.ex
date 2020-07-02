defmodule Tune.Spotify.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: Tune.Spotify.SessionRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Tune.Spotify.SessionSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def ensure_session(token) do
    case start_session(token) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error
    end
  end

  defp start_session(token) do
    DynamicSupervisor.start_child(Tune.Spotify.SessionSupervisor, {Tune.Spotify.Session, token})
  end
end

